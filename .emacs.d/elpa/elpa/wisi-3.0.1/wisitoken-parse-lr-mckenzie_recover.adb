--  Abstract :
--
--  See spec
--
--  Copyright (C) 2017 - 2020 Free Software Foundation, Inc.
--
--  This library is free software;  you can redistribute it and/or modify it
--  under terms of the  GNU General Public License  as published by the Free
--  Software  Foundation;  either version 3,  or (at your  option) any later
--  version. This library is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN-
--  TABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
--  As a special exception under Section 7 of GPL version 3, you are granted
--  additional permissions described in the GCC Runtime Library Exception,
--  version 3.1, as published by the Free Software Foundation.

pragma License (Modified_GPL);

with Ada.Characters.Handling;
with Ada.Exceptions;
with Ada.Unchecked_Deallocation;
with System.Multiprocessors;
with WisiToken.Parse.LR.McKenzie_Recover.Base;
with WisiToken.Parse.LR.McKenzie_Recover.Explore;
with WisiToken.Parse.LR.Parser_Lists;
package body WisiToken.Parse.LR.McKenzie_Recover is
   use all type System.Multiprocessors.CPU_Range;

   type Supervisor_Access is access all Base.Supervisor;
   type Shared_Access is access all Base.Shared;

   task type Worker_Task is
      entry Start
        (ID     : in Integer;
         Super  : in Supervisor_Access;
         Shared : in Shared_Access);
      --  Start getting parser/configs to check from Config_Store. Stop when
      --  Super reports All_Done;

      entry Done;
      --  Available after Super has reported All_Done.
   end Worker_Task;

   type Worker_Access is access Worker_Task;
   procedure Free is new Ada.Unchecked_Deallocation (Worker_Task, Worker_Access);

   task body Worker_Task
   is
      use all type Base.Config_Status;
      Super  : Supervisor_Access;
      Shared : Shared_Access;

      Status : Base.Config_Status := Valid;
   begin
      loop
         select
            accept Start
              (ID     : in Integer;
               Super  : in Supervisor_Access;
               Shared : in Shared_Access)

            do
               Task_Attributes.Set_Value (ID);
               Worker_Task.Super  := Super;
               Worker_Task.Shared := Shared;
            end Start;
         or
            terminate;
         end select;

         loop
            Explore.Process_One (Super, Shared, Status);
            exit when Status = All_Done;
         end loop;

         accept Done;

         Super  := null;
         Shared := null;
      end loop;

   exception
   when E : others =>
      Super.Fatal (E);
   end Worker_Task;

   Worker_Tasks : array (1 .. System.Multiprocessors.CPU_Range'Max (1, System.Multiprocessors.Number_Of_CPUs - 1)) of
     Worker_Access;
   --  Declaring an array of tasks directly causes a circular elaboration
   --  problem, and would mean a task that terminates due to an exception
   --  is never restarted.

   procedure To_Recover
     (Parser_Stack : in     Parser_Lists.Parser_Stacks.Stack;
      Tree         : in     Syntax_Trees.Tree;
      Stack        : in out Recover_Stacks.Stack)
   is
      Depth : constant SAL.Peek_Type := Parser_Stack.Depth;
   begin
      pragma Assert (Stack.Depth = 0);
      if Stack.Size < Depth then
         raise SAL.Programmer_Error with "recover stack needs more space;" & Depth'Image;
      end if;
      for I in reverse 1 .. Depth loop
         declare
            Item  : Parser_Lists.Parser_Stack_Item renames Parser_Stack (I);
            Token : constant Recover_Token := (if I = Depth then (others => <>) else Tree.Recover_Token (Item.Token));
         begin
            Stack.Push ((Item.State, Item.Token, Token));
         end;
      end loop;
   end To_Recover;

   procedure Recover_Init
     (Shared_Parser : in out LR.Parser.Parser;
      Parser_State  : in out Parser_Lists.Parser_State)
   is
      use all type WisiToken.Parse.LR.Parser.Language_Fixes_Access;

      Trace  : WisiToken.Trace'Class renames Shared_Parser.Trace.all;
      Config : Configuration;
      Error  : Parse_Error renames Parser_State.Errors (Parser_State.Errors.Last);
   begin
      Parser_State.Recover.Enqueue_Count := Parser_State.Recover.Enqueue_Count + 1;

      Config.Resume_Token_Goal := Parser_State.Shared_Token + Shared_Parser.Table.McKenzie_Param.Check_Limit;

      if Trace_McKenzie > Outline then
         Trace.New_Line;
         Trace.Put_Line
           ("parser" & Integer'Image (Parser_State.Label) &
              ": State" & State_Index'Image (Parser_State.Stack (1).State) &
              " Current_Token" & Parser_State.Tree.Image (Parser_State.Current_Token, Trace.Descriptor.all) &
              " Resume_Token_Goal" & WisiToken.Token_Index'Image (Config.Resume_Token_Goal));
         Trace.Put_Line
           ((case Error.Label is
             when Action => "Action",
             when Check => "Check, " & Semantic_Checks.Image (Error.Check_Status, Trace.Descriptor.all),
             when Message => raise SAL.Programmer_Error));
         if Trace_McKenzie > Extra then
            Put_Line
              (Trace, Parser_State.Label, Parser_Lists.Image
                 (Parser_State.Stack, Trace.Descriptor.all, Parser_State.Tree));
         end if;
      end if;

      --  Additional initialization of Parser_State.Recover is done in
      --  Supervisor.Initialize.

      To_Recover (Parser_State.Stack, Parser_State.Tree, Config.Stack);

      --  Parser_State.Recover_Insert_Delete must be empty (else we would not get
      --  here). Therefore Parser_State current token is in
      --  Shared_Parser.Shared_Token.

      Config.Current_Shared_Token := Parser_State.Shared_Token;

      case Error.Label is
      when Action =>
         Config.Error_Token := Parser_State.Tree.Recover_Token (Error.Error_Token);
         if Trace_McKenzie > Detail then
            Put ("enqueue", Trace, Parser_State.Label, Shared_Parser.Terminals, Config,
                 Task_ID => False);
         end if;

      when Check =>
         if Shared_Parser.Language_Fixes = null then
            --  The only fix is to ignore the error.
            if Trace_McKenzie > Detail then
               Put ("enqueue", Trace, Parser_State.Label, Shared_Parser.Terminals, Config,
                    Task_ID => False);
            end if;

         else
            --  Undo the reduction that encountered the error, let Process_One
            --  enqueue possible solutions. We leave the cost at 0, since this is
            --  the root config. Later logic will enqueue the 'ignore error'
            --  solution; see McKenzie_Recover.Explore Process_One.

            Config.Check_Status      := Error.Check_Status;
            Config.Error_Token       := Config.Stack.Peek.Token;
            Config.Check_Token_Count := Undo_Reduce (Config.Stack, Parser_State.Tree);

            Config_Op_Arrays.Append (Config.Ops, (Undo_Reduce, Config.Error_Token.ID, Config.Check_Token_Count));

            if Trace_McKenzie > Detail then
               Put ("undo_reduce " & Image
                      (Config.Error_Token.ID, Trace.Descriptor.all), Trace, Parser_State.Label,
                    Shared_Parser.Terminals, Config, Task_ID => False);
            end if;
         end if;

      when Message =>
         --  Last error entry should be the failure that caused us to enter
         --  recovery.
         raise SAL.Programmer_Error;
      end case;

      Parser_State.Recover.Config_Heap.Add (Config);
   end Recover_Init;

   function Recover (Shared_Parser : in out LR.Parser.Parser) return Recover_Status
   is
      use all type Parser.Post_Recover_Access;
      Trace : WisiToken.Trace'Class renames Shared_Parser.Trace.all;

      Parsers : Parser_Lists.List renames Shared_Parser.Parsers;

      Current_Parser : Parser_Lists.Cursor;

      Super : aliased Base.Supervisor
        (Trace'Access,
         Check_Delta_Limit => Shared_Parser.Table.McKenzie_Param.Check_Delta_Limit,
         Enqueue_Limit     => Shared_Parser.Table.McKenzie_Param.Enqueue_Limit,
         Parser_Count      => Parsers.Count);

      Shared : aliased Base.Shared
        (Shared_Parser.Trace,
         Shared_Parser.Lexer.all'Access,
         Shared_Parser.Table,
         Shared_Parser.Language_Fixes,
         Shared_Parser.Language_Matching_Begin_Tokens,
         Shared_Parser.Language_String_ID_Set,
         Shared_Parser.Terminals'Access,
         Shared_Parser.Line_Begin_Token'Access);

      Task_Count : constant System.Multiprocessors.CPU_Range :=
        (if Shared_Parser.Table.McKenzie_Param.Task_Count = 0
         then Worker_Tasks'Last
         --  Keep one CPU free for this main task, and the user.
         else Shared_Parser.Table.McKenzie_Param.Task_Count);

   begin
      if Trace_McKenzie > Outline then
         Trace.New_Line;
         Trace.Put_Line (" McKenzie error recovery");
      end if;

      Super.Initialize (Parsers'Unrestricted_Access, Shared_Parser.Terminals'Unrestricted_Access);

      for Parser_State of Parsers loop
         Recover_Init (Shared_Parser, Parser_State);
      end loop;

      if Trace_McKenzie > Outline then
         Trace.New_Line;
         Trace.Put_Line (Task_Count'Image & " parallel tasks");
      end if;

      for I in Worker_Tasks'First .. Task_Count loop
         if Worker_Tasks (I) = null then
            Worker_Tasks (I) := new Worker_Task;
            if Debug_Mode then
               Trace.Put_Line ("new Worker_Task" & System.Multiprocessors.CPU_Range'Image (I));
            end if;

         elsif Worker_Tasks (I)'Terminated then
            Free (Worker_Tasks (I));
            Worker_Tasks (I) := new Worker_Task;
            if Debug_Mode then
               Trace.Put_Line ("recreated Worker_Task" & System.Multiprocessors.CPU_Range'Image (I));
            end if;
         end if;

         Worker_Tasks (I).Start (Integer (I), Super'Unchecked_Access, Shared'Unchecked_Access);
      end loop;

      declare
         use Ada.Exceptions;
         ID      : Exception_Id;
         Message : Ada.Strings.Unbounded.Unbounded_String;
      begin
         Super.Done (ID, Message); -- Wait for all parsers to fail or succeed

         --  Ensure all worker tasks stop getting configs before proceeding;
         --  otherwise local variables disappear while the task is still trying
         --  to access them.
         for I in Worker_Tasks'First .. Task_Count loop
            if not Worker_Tasks (I)'Terminated then
               Worker_Tasks (I).Done;
            end if;
         end loop;

         if ID /= Null_Id then
            Raise_Exception (ID, -Message);
         end if;
      end;

      --  Adjust parser state for each successful recovery.
      --
      --  One option here would be to keep only the parser with the least
      --  cost fix. However, the normal reason for having multiple parsers
      --  is to resolve a grammar ambiguity; the least cost fix might
      --  resolve the ambiguity the wrong way. As could any other fix, of
      --  course.

      --  Spawn new parsers for multiple solutions.
      --
      --  We could try to check here for redundant solutions; configs for a
      --  parser that have the same or "equivalent" ops. But those will be
      --  caught in the main parse by the check for duplicate state; doing
      --  the same check here is premature optimization.
      declare
         use Parser_Lists;

         Cur         : Cursor             := Parsers.First;
         Solutions   : SAL.Base_Peek_Type := 0;
         Spawn_Limit : SAL.Base_Peek_Type := Shared_Parser.Max_Parallel; -- per parser
      begin
         for Parser of Parsers loop
            if Parser.Recover.Success then
               Solutions := Solutions + Parser.Recover.Results.Count;
            end if;
         end loop;

         if Solutions > Shared_Parser.Max_Parallel and Trace_McKenzie > Outline then
            Trace.Put_Line ("too many parallel parsers required in recover; dropping some solutions");
            Spawn_Limit := Shared_Parser.Max_Parallel / Parsers.Count;
         end if;

         loop
            declare
               Data : McKenzie_Data renames State_Ref (Cur).Recover;
            begin
               if Data.Success then
                  if Trace_McKenzie > Outline then
                     Trace.Put_Line
                       (Integer'Image (Label (Cur)) &
                          ": succeed" & SAL.Base_Peek_Type'Image (Data.Results.Count) &
                          ", enqueue" & Integer'Image (Data.Enqueue_Count) &
                          ", check " & Integer'Image (Data.Check_Count) &
                          ", cost: " & Integer'Image (Data.Results.Min_Key));
                  end if;

                  if Data.Results.Count > 1 then
                     for I in 1 .. SAL.Base_Peek_Type'Min (Spawn_Limit, Data.Results.Count - 1) loop
                        Parsers.Prepend_Copy (Cur); --  does not copy recover
                        if Trace_McKenzie > Outline or Trace_Parse > Outline then
                           Trace.Put_Line
                             ("spawn parser" & Integer'Image (Parsers.First.Label) & " from " &
                                Trimmed_Image (Cur.Label) & " (" & Trimmed_Image (Integer (Parsers.Count)) &
                                " active)");
                           Put ("", Trace, Parsers.First.Label, Shared_Parser.Terminals,
                                Data.Results.Peek, Task_ID => False, Strategy => True);
                        end if;

                        State_Ref (Parsers.First).Recover.Results.Add (Data.Results.Remove);
                        State_Ref (Parsers.First).Recover.Success := True;
                     end loop;
                  end if;

                  if Trace_McKenzie > Outline or Trace_Parse > Outline then
                     Put ("", Trace, Cur.State_Ref.Label, Shared_Parser.Terminals, Data.Results.Peek,
                          Task_ID => False, Strategy => True);
                  end if;
               else
                  if Trace_McKenzie > Outline then
                     Trace.Put_Line
                       (Integer'Image (Cur.Label) &
                          ": fail, enqueue" & Integer'Image (Data.Enqueue_Count) &
                          (if Data.Config_Full_Count > 0 then ", config_full" & Data.Config_Full_Count'Image else "") &
                          ", check " & Integer'Image (Data.Check_Count) &
                          ", max shared_token " & WisiToken.Token_Index'Image (Shared_Parser.Terminals.Last_Index));
                  end if;
               end if;

            end;
            Next (Cur);
            exit when Is_Done (Cur);
         end loop;
      end;

      --  Edit Parser_State to apply solutions.

      --  We don't use 'for Parser_State of Parsers loop' here,
      --  because we might need to terminate a parser.
      Current_Parser := Parsers.First;
      loop
         exit when Current_Parser.Is_Done;

         if Current_Parser.State_Ref.Recover.Success then
            begin
               --  Can't have active 'renames State_Ref' when terminate a parser
               declare
                  use Parser_Lists;
                  use Config_Op_Arrays, Config_Op_Array_Refs;
                  use Sorted_Insert_Delete_Arrays;

                  Parser_State : Parser_Lists.Parser_State renames Current_Parser.State_Ref;

                  Descriptor : WisiToken.Descriptor renames Shared_Parser.Trace.Descriptor.all;
                  Tree       : Syntax_Trees.Tree renames Parser_State.Tree;
                  Data       : McKenzie_Data renames Parser_State.Recover;
                  Result     : Configuration renames Data.Results.Peek;

                  Min_Op_Token_Index        : WisiToken.Token_Index := WisiToken.Token_Index'Last;
                  Min_Push_Back_Token_Index : WisiToken.Token_Index := WisiToken.Token_Index'Last;

                  Stack_Matches_Ops     : Boolean := True;
                  Shared_Token_Changed  : Boolean := False;
                  Current_Token_Virtual : Boolean := False;

                  Sorted_Insert_Delete : aliased Sorted_Insert_Delete_Arrays.Vector;

                  procedure Apply_Prev_Token
                  is begin
                     loop
                        exit when not Parser_State.Prev_Deleted.Contains (Parser_State.Shared_Token);
                        Parser_State.Shared_Token := Parser_State.Shared_Token + 1;
                     end loop;
                  end Apply_Prev_Token;

               begin
                  --  The verb will be reset by the main parser; just indicate the
                  --  parser recovered from the error.
                  Parser_State.Set_Verb (Shift);

                  Parser_State.Errors (Parser_State.Errors.Last).Recover := Result;

                  Parser_State.Resume_Token_Goal := Result.Resume_Token_Goal;

                  if Trace_McKenzie > Extra then
                     Put_Line (Trace, Parser_State.Label, "before Ops applied:", Task_ID => False);
                     Put_Line
                       (Trace, Parser_State.Label, "stack " & Image (Parser_State.Stack, Descriptor, Tree),
                        Task_ID => False);
                     Put_Line
                       (Trace, Parser_State.Label, "Shared_Token  " & Image
                          (Parser_State.Shared_Token, Shared_Parser.Terminals, Descriptor),
                        Task_ID => False);
                     Put_Line
                       (Trace, Parser_State.Label, "Current_Token " & Parser_State.Tree.Image
                          (Parser_State.Current_Token, Descriptor),
                        Task_ID => False);
                  end if;

                  --  We don't apply all Ops to the parser stack here, because that
                  --  requires updating the syntax tree as well, and we want to let the
                  --  main parser do that, partly as a double check on the algorithms
                  --  here.
                  --
                  --  However, the main parser can only apply Insert and Delete ops; we
                  --  must apply Push_Back and Undo_Reduce here. Note that Fast_Forward
                  --  ops are just for bookkeeping.
                  --
                  --  In order to apply Undo_Reduce, we also need to apply any preceding
                  --  ops. See test_mckenzie_recover.adb Missing_Name_2 for an example
                  --  of multiple Undo_Reduce. On the other hand, Push_Back can be
                  --  applied without the preceding ops.
                  --
                  --  A Push_Back can go back past preceding ops, including Undo_Reduce;
                  --  there's no point in applying ops that are later superceded by such
                  --  a Push_Back. See test_mckenzie_recover.adb Out_Of_Order_Ops for an
                  --  example.
                  --
                  --  Push_Back can also go back past a previous error recovery; we must
                  --  apply Parser_State.Prev_Deleted here as well, when computing
                  --  Shared_Token.
                  --
                  --  So first we go thru Ops to find the earliest Push_Back. Then we
                  --  apply ops that are before that point, up to the first Insert or
                  --  Fast_Forward. After that, we enqueue Insert and Delete ops on
                  --  Parser_State.Recover_Insert_Delete, in token_index order, and any
                  --  Undo_Reduce are rejected.
                  --
                  --  Then the main parser parses the edited input stream.
                  --
                  --  There's no need to modify Parser_State.Tree. Any tree nodes
                  --  created by the failed parse that are pushed back are useful for
                  --  error repair, and will just be ignored in future parsing. This
                  --  also avoids enlarging a non-flushed branched tree, which saves
                  --  time and space.

                  for I in First_Index (Result.Ops) .. Last_Index (Result.Ops) loop
                     declare
                        Op : Config_Op renames Constant_Ref (Result.Ops, I);
                     begin
                        case Op.Op is
                        when Fast_Forward =>
                           if Op.FF_Token_Index < Min_Op_Token_Index then
                              Min_Op_Token_Index := Op.FF_Token_Index;
                           end if;

                        when Undo_Reduce =>
                           null;

                        when Push_Back =>
                           if Op.PB_Token_Index /= Invalid_Token_Index then
                              if Op.PB_Token_Index < Min_Op_Token_Index then
                                 Min_Op_Token_Index := Op.PB_Token_Index;
                              end if;
                              if Op.PB_Token_Index < Min_Push_Back_Token_Index then
                                 Min_Push_Back_Token_Index := Op.PB_Token_Index;
                              end if;
                           end if;

                        when Insert =>
                           if Op.Ins_Token_Index /= Invalid_Token_Index then
                              if Op.Ins_Token_Index < Min_Op_Token_Index then
                                 Min_Op_Token_Index := Op.Ins_Token_Index;
                              end if;
                              if Op.Ins_Token_Index < Min_Push_Back_Token_Index then
                                 Min_Push_Back_Token_Index := Op.Ins_Token_Index;
                              end if;
                           end if;

                        when Delete =>
                           if Op.Del_Token_Index /= Invalid_Token_Index then
                              if Op.Del_Token_Index < Min_Op_Token_Index then
                                 Min_Op_Token_Index := Op.Del_Token_Index;
                              end if;
                              if Op.Del_Token_Index < Min_Push_Back_Token_Index then
                                 Min_Push_Back_Token_Index := Op.Del_Token_Index;
                              end if;
                           end if;

                        end case;
                     end;
                  end loop;

                  for I in First_Index (Result.Ops) .. Last_Index (Result.Ops) loop
                     declare
                        Op : Config_Op renames Constant_Ref (Result.Ops, I);
                     begin
                        case Op.Op is
                        when Fast_Forward =>
                           Stack_Matches_Ops := False;

                        when Undo_Reduce =>
                           if not Stack_Matches_Ops then
                              if Trace_McKenzie > Outline then
                                 Put_Line
                                   (Trace, Parser_State.Label, "Undo_Reduce after insert or fast_forward",
                                    Task_ID => False);
                              end if;
                              raise Bad_Config;
                           end if;

                           declare
                              Item : constant Parser_Lists.Parser_Stack_Item := Parser_State.Stack.Pop;
                           begin
                              case Tree.Label (Item.Token) is
                              when Syntax_Trees.Shared_Terminal |
                                Syntax_Trees.Virtual_Identifier |
                                Syntax_Trees.Virtual_Terminal =>
                                 if Trace_McKenzie > Outline then
                                    Put_Line
                                      (Trace, Parser_State.Label, "expecting nonterminal, found " &
                                         Image (Tree.ID (Item.Token), Trace.Descriptor.all),
                                       Task_ID => False);
                                 end if;
                                 raise Bad_Config;

                              when Syntax_Trees.Nonterm =>
                                 for C of Tree.Children (Item.Token) loop
                                    Parser_State.Stack.Push ((Tree.State (C), C));
                                 end loop;
                              end case;
                           end;

                        when Push_Back =>
                           if Stack_Matches_Ops then
                              Parser_State.Stack.Pop;
                              if Op.PB_Token_Index /= Invalid_Token_Index then
                                 Parser_State.Shared_Token := Op.PB_Token_Index;
                                 Shared_Token_Changed      := True;
                              end if;

                           elsif Op.PB_Token_Index = Min_Op_Token_Index then
                              loop
                                 --  Multiple push_backs can have the same Op.PB_Token_Index, so we may
                                 --  already be at the target.
                                 exit when Parser_State.Shared_Token <= Op.PB_Token_Index and
                                   (Parser_State.Stack.Depth = 1 or else
                                      Tree.Min_Terminal_Index (Parser_State.Stack (1).Token) /= Invalid_Token_Index);
                                 --  also push back empty tokens.

                                 declare
                                    Item : constant Parser_Lists.Parser_Stack_Item := Parser_State.Stack.Pop;

                                    Min_Index : constant Base_Token_Index :=
                                      Parser_State.Tree.Min_Terminal_Index (Item.Token);
                                 begin
                                    if Min_Index /= Invalid_Token_Index then
                                       Shared_Token_Changed := True;
                                       Parser_State.Shared_Token := Min_Index;
                                    end if;
                                 end;
                              end loop;
                              pragma Assert (Parser_State.Shared_Token = Op.PB_Token_Index);
                           end if;

                        when Insert =>
                           if Stack_Matches_Ops and Op.Ins_Token_Index = Parser_State.Shared_Token then
                              --  This is the first Insert. Even if a later Push_Back supercedes it,
                              --  we record Stack_Matches_Ops false here.
                              Stack_Matches_Ops := False;

                              if Op.Ins_Token_Index <= Min_Push_Back_Token_Index then
                                 Parser_State.Current_Token := Parser_State.Tree.Add_Terminal (Op.Ins_ID);
                                 Current_Token_Virtual      := True;
                              else
                                 if Is_Full (Sorted_Insert_Delete) then
                                    raise Bad_Config;
                                 else
                                    Insert (Sorted_Insert_Delete, Op);
                                 end if;
                              end if;
                           else
                              if Is_Full (Sorted_Insert_Delete) then
                                 raise Bad_Config;
                              else
                                 Insert (Sorted_Insert_Delete, Op);
                              end if;
                           end if;

                        when Delete =>
                           if Stack_Matches_Ops and Op.Del_Token_Index = Parser_State.Shared_Token then
                              --  We can apply multiple deletes.
                              Parser_State.Shared_Token := Op.Del_Token_Index + 1;
                              Apply_Prev_Token;
                              Shared_Token_Changed      := True;
                           else
                              if Is_Full (Sorted_Insert_Delete) then
                                 raise Bad_Config;
                              else
                                 Insert (Sorted_Insert_Delete, Op);
                              end if;
                           end if;
                        end case;
                     end;
                  end loop;

                  --  We may not have processed the current Insert or Delete above, if
                  --  they are after a fast_forward.
                  for I in First_Index (Sorted_Insert_Delete) .. Last_Index (Sorted_Insert_Delete) loop
                     declare
                        Op : Insert_Delete_Op renames Insert_Delete_Array_Refs.Constant_Ref (Sorted_Insert_Delete, I);
                     begin
                        if Token_Index (Op) = Parser_State.Shared_Token and not Current_Token_Virtual then
                           case Insert_Delete_Op_Label'(Op.Op) is
                           when Insert =>
                              Parser_State.Current_Token := Parser_State.Tree.Add_Terminal (ID (Op));
                              Current_Token_Virtual      := True;

                           when Delete =>
                              Parser_State.Shared_Token := Op.Del_Token_Index + 1;
                              Apply_Prev_Token;
                              Shared_Token_Changed      := True;
                           end case;
                        else
                           Parser_State.Recover_Insert_Delete.Put (Op);
                        end if;
                     end;
                  end loop;

                  --  If not Shared_Token_Changed, Shared_Token is the error token,
                  --  which is the next token to read. If Shared_Token_Changed, we have
                  --  set Shared_Token consistent with that; it is the next token to
                  --  read. If Current_Token_Virtual, then after all the virtual tokens
                  --  are inserted, the main parser would normally increment
                  --  Parser_State.Shared_Token to get the next token, but we don't want
                  --  that now. We could set Shared_Token to 1 less, but this way the
                  --  debug messages all show the expected Shared_Terminal.

                  Parser_State.Inc_Shared_Token := not Current_Token_Virtual;

                  --  The main parser always sets Current_Token to be the syntax tree
                  --  node containing Shared_Token; ensure that is true here (virtual
                  --  tokens where handled above).

                  if (not Current_Token_Virtual) and Shared_Token_Changed then
                     Parser_State.Current_Token := Parser_State.Tree.Add_Terminal
                       (Parser_State.Shared_Token, Shared_Parser.Terminals);
                  end if;

                  if Trace_McKenzie > Extra then
                     Put_Line (Trace, Parser_State.Label, "after Ops applied:", Task_ID => False);
                     Put_Line
                       (Trace, Parser_State.Label, "stack " & Parser_Lists.Image
                          (Parser_State.Stack, Descriptor, Tree),
                        Task_ID => False);
                     Put_Line
                       (Trace, Parser_State.Label, "Shared_Token  " & Image
                          (Parser_State.Shared_Token, Shared_Parser.Terminals, Descriptor), Task_ID => False);
                     Put_Line
                       (Trace, Parser_State.Label, "Current_Token " & Parser_State.Tree.Image
                          (Parser_State.Current_Token, Descriptor), Task_ID => False);
                     Put_Line
                       (Trace, Parser_State.Label, "recover_insert_delete " & Image
                          (Parser_State.Recover_Insert_Delete, Descriptor), Task_ID => False);
                     Put_Line
                       (Trace, Parser_State.Label, "inc_shared_token " & Boolean'Image (Parser_State.Inc_Shared_Token) &
                          " parser verb " & All_Parse_Action_Verbs'Image (Parser_State.Verb),
                        Task_ID => False);
                  end if;
               end;
            exception
            when Bad_Config =>
               if Parsers.Count = 1 then
                  --  Oops. just give up
                  return Fail_Programmer_Error;
               end if;
               Parsers.Terminate_Parser (Current_Parser, "bad config in recover", Trace, Shared_Parser.Terminals);
            end;
         end if;
         Current_Parser.Next;
      end loop;

      if Shared_Parser.Post_Recover /= null then
         Shared_Parser.Post_Recover.all;
      end if;

      return Super.Recover_Result;

   exception
   when E : others =>
      if Debug_Mode then
         Trace.Put (Ada.Exceptions.Exception_Name (E) & ": " & Ada.Exceptions.Exception_Message (E));
         raise;
      else
         return Fail_Programmer_Error;
      end if;
   end Recover;

   ----------
   --  Spec private subprograms; for language-specific
   --  child packages.

   procedure Check (ID : Token_ID; Expected_ID : in Token_ID)
   is begin
      pragma Assert (ID = Expected_ID, Token_ID'Image (ID) & " /=" & Token_ID'Image (Expected_ID));
   end Check;

   function Current_Token
     (Terminals                 :         in     Base_Token_Arrays.Vector;
      Terminals_Current         :         in out WisiToken.Base_Token_Index;
      Restore_Terminals_Current :            out WisiToken.Base_Token_Index;
      Insert_Delete             : aliased in out Sorted_Insert_Delete_Arrays.Vector;
      Current_Insert_Delete     :         in out SAL.Base_Peek_Type;
      Prev_Deleted              :         in     Recover_Token_Index_Arrays.Vector)
     return Base_Token
   is
      use Sorted_Insert_Delete_Arrays;
      use Insert_Delete_Array_Refs;

      procedure Inc_I_D
      is begin
         Current_Insert_Delete := Current_Insert_Delete + 1;
         if Current_Insert_Delete > Last_Index (Insert_Delete) then
            Current_Insert_Delete := No_Insert_Delete;
            Clear (Insert_Delete);
         end if;
      end Inc_I_D;

   begin
      if Terminals_Current = Invalid_Token_Index then
         --  Happens with really bad syntax; see test_mckenzie_recover.adb Error_4.
         raise Bad_Config;
      end if;

      loop
         if Current_Insert_Delete = No_Insert_Delete then
            Restore_Terminals_Current := Terminals_Current;
            return Terminals (Terminals_Current);

         elsif Token_Index (Constant_Ref (Insert_Delete, Current_Insert_Delete)) = Terminals_Current then
            declare
               Op : Insert_Delete_Op renames Constant_Ref (Insert_Delete, Current_Insert_Delete);
            begin
               case Insert_Delete_Op_Label (Op.Op) is
               when Insert =>
                  --  Decrement Terminals_Current so Next_Token knows it should always
                  --  increment it. Save the initial value, to restore in case of error.
                  Restore_Terminals_Current := Terminals_Current;
                  Terminals_Current         := Terminals_Current - 1;
                  return (ID => ID (Op), others => <>);

               when Delete =>
                  Terminals_Current    := Terminals_Current + 1;
                  loop
                     exit when not Prev_Deleted.Contains (Terminals_Current);
                     Terminals_Current := Terminals_Current + 1;
                  end loop;
                  Restore_Terminals_Current := Terminals_Current;
                  Inc_I_D;
               end case;
            end;
         else
            return Terminals (Terminals_Current);
         end if;
      end loop;
   end Current_Token;

   function Current_Token_ID_Peek
     (Terminals             :         in Base_Token_Arrays.Vector;
      Terminals_Current     :         in Base_Token_Index;
      Insert_Delete         : aliased in Sorted_Insert_Delete_Arrays.Vector;
      Current_Insert_Delete :         in SAL.Base_Peek_Type)
     return Token_ID
   is
      use Insert_Delete_Array_Refs;

      Result : Token_ID;
   begin
      if Terminals_Current = Base_Token_Index'First then
         --  Happens with really bad syntax.
         raise Bad_Config;
      end if;

      --  First set Result from Terminals; may be overridden by
      --  Insert_Delete below.
      Result := Terminals (Terminals_Current).ID;

      if Current_Insert_Delete = No_Insert_Delete then
         null;

      elsif Token_Index (Constant_Ref (Insert_Delete, Current_Insert_Delete)) = Terminals_Current then
         declare
            Op : Insert_Delete_Op renames Constant_Ref (Insert_Delete, Current_Insert_Delete);
         begin
            case Insert_Delete_Op_Label (Op.Op) is
            when Insert =>
               Result := Op.Ins_ID;

            when Delete =>
               --  This should have been handled in Check
               raise SAL.Programmer_Error;
            end case;
         end;
      end if;
      return Result;
   end Current_Token_ID_Peek;

   procedure Current_Token_ID_Peek_3
     (Terminals             :         in     Base_Token_Arrays.Vector;
      Terminals_Current     :         in     Base_Token_Index;
      Insert_Delete         : aliased in     Sorted_Insert_Delete_Arrays.Vector;
      Current_Insert_Delete :         in     SAL.Base_Peek_Type;
      Prev_Deleted          :         in     Recover_Token_Index_Arrays.Vector;
      Tokens                :            out Token_ID_Array_1_3)
   is
      Terminals_Next : WisiToken.Token_Index := Terminals_Current + 1;
   begin
      if Terminals_Current = Base_Token_Index'First then
         --  Happens with really bad syntax; see test_mckenzie_recover.adb Error_4.
         raise Bad_Config;
      end if;

      --  First set Tokens from Terminals; may be overridden by
      --  Insert_Delete below.
      Tokens (1) := Terminals (Terminals_Current).ID;
      loop
         exit when not Prev_Deleted.Contains (Terminals_Next);
         Terminals_Next := Terminals_Next + 1;
      end loop;
      if Terminals_Next <= Terminals.Last_Index then
         Tokens (2) := Terminals (Terminals_Next).ID;
         loop
            Terminals_Next := Terminals_Next + 1;
            exit when not Prev_Deleted.Contains (Terminals_Next);
         end loop;
         if Terminals_Next <= Terminals.Last_Index then
            Tokens (3) := Terminals (Terminals_Next).ID;
         else
            Tokens (3) := Invalid_Token_ID;
         end if;
      else
         Tokens (2) := Invalid_Token_ID;
         Tokens (3) := Invalid_Token_ID;
      end if;

      if Current_Insert_Delete = No_Insert_Delete then
         null;
      else
         for I in Tokens'Range loop
            declare
               use Sorted_Insert_Delete_Arrays, Insert_Delete_Array_Refs;
               J : constant SAL.Base_Peek_Type := Current_Insert_Delete + SAL.Peek_Type (I) - 1;
            begin
               if (J in First_Index (Insert_Delete) .. Last_Index (Insert_Delete)) and then
                 Token_Index (Constant_Ref (Insert_Delete, J)) = Terminals_Current
               then
                  declare
                     Op : Insert_Delete_Op renames Constant_Ref (Insert_Delete, J);
                  begin
                     case Insert_Delete_Op_Label (Op.Op) is
                     when Insert =>
                        Tokens (I) := Op.Ins_ID;

                     when Delete =>
                        --  This should have been handled in Check
                        raise SAL.Programmer_Error;
                     end case;
                  end;
               end if;
            end;
         end loop;
      end if;
   end Current_Token_ID_Peek_3;

   procedure Delete_Check
     (Terminals : in     Base_Token_Arrays.Vector;
      Config    : in out Configuration;
      ID        : in     Token_ID)
   is
      use Config_Op_Arrays;
      use Sorted_Insert_Delete_Arrays;
      Op : constant Config_Op := (Delete, ID, Config.Current_Shared_Token);
   begin
      Check (Terminals (Config.Current_Shared_Token).ID, ID);
      if Is_Full (Config.Ops) or Is_Full (Config.Insert_Delete) then
         raise Bad_Config;
      end if;
      Append (Config.Ops, Op);
      Insert (Config.Insert_Delete, Op);
      Config.Current_Insert_Delete := 1;
   end Delete_Check;

   procedure Delete_Check
     (Terminals : in     Base_Token_Arrays.Vector;
      Config    : in out Configuration;
      Index     : in out WisiToken.Token_Index;
      ID        : in     Token_ID)
   is begin
      Check (Terminals (Index).ID, ID);
      Delete (Terminals, Config, Index);
   end Delete_Check;

   procedure Delete
     (Terminals : in     Base_Token_Arrays.Vector;
      Config    : in out Configuration;
      Index     : in out WisiToken.Token_Index)
   is
      use Config_Op_Arrays;
      use Sorted_Insert_Delete_Arrays;
      Op : constant Config_Op := (Delete, Terminals (Index).ID, Index);
   begin
      if Is_Full (Config.Ops) or Is_Full (Config.Insert_Delete) then
         raise Bad_Config;
      end if;
      Append (Config.Ops, Op);
      Insert (Config.Insert_Delete, Op);
      Config.Current_Insert_Delete := 1;
      Index := Index + 1;
   end Delete;

   procedure Find_ID
     (Config         : in     Configuration;
      ID             : in     Token_ID;
      Matching_Index : in out SAL.Peek_Type)
   is begin
      loop
         exit when Matching_Index = Config.Stack.Depth; -- Depth has Invalid_Token_ID
         declare
            Stack_ID : Token_ID renames Config.Stack.Peek (Matching_Index).Token.ID;
         begin
            exit when Stack_ID = ID;
         end;
         Matching_Index := Matching_Index + 1;
      end loop;
   end Find_ID;

   procedure Find_ID
     (Config         : in     Configuration;
      IDs            : in     Token_ID_Set;
      Matching_Index : in out SAL.Peek_Type)
   is begin
      loop
         exit when Matching_Index >= Config.Stack.Depth; -- Depth has Invalid_Token_ID
         declare
            ID : Token_ID renames Config.Stack.Peek (Matching_Index).Token.ID;
         begin
            exit when ID in IDs'First .. IDs'Last and then IDs (ID);
         end;
         Matching_Index := Matching_Index + 1;
      end loop;
   end Find_ID;

   procedure Find_Descendant_ID
     (Tree           : in     Syntax_Trees.Tree;
      Config         : in     Configuration;
      ID             : in     Token_ID;
      ID_Set         : in     Token_ID_Set;
      Matching_Index : in out SAL.Peek_Type)
   is
      use Syntax_Trees;
   begin
      loop
         exit when Matching_Index >= Config.Stack.Depth; -- Depth has Invalid_Token_ID
         exit when Config.Stack.Peek (Matching_Index).Token.ID in ID_Set'Range and then
           (ID_Set (Config.Stack.Peek (Matching_Index).Token.ID) and
              (Config.Stack.Peek (Matching_Index).Tree_Index /= Invalid_Node_Index and then
                 Tree.Find_Descendant (Config.Stack.Peek (Matching_Index).Tree_Index, ID) /= Invalid_Node_Index));

         Matching_Index := Matching_Index + 1;
      end loop;
   end Find_Descendant_ID;

   procedure Find_Matching_Name
     (Config              : in     Configuration;
      Lexer               : access constant WisiToken.Lexer.Instance'Class;
      Name                : in     String;
      Matching_Name_Index : in out SAL.Peek_Type;
      Case_Insensitive    : in     Boolean)
   is
      use Ada.Characters.Handling;
      Match_Name : constant String := (if Case_Insensitive then To_Lower (Name) else Name);
   begin
      loop
         exit when Matching_Name_Index >= Config.Stack.Depth; -- Depth has Invalid_Token_ID
         declare
            Token       : Recover_Token renames Config.Stack.Peek (Matching_Name_Index).Token;
            Name_Region : constant Buffer_Region :=
              (if Token.Name = Null_Buffer_Region
               then Token.Byte_Region
               else Token.Name);
         begin
            exit when Name_Region /= Null_Buffer_Region and then
              Match_Name =
              (if Case_Insensitive
               then To_Lower (Lexer.Buffer_Text (Name_Region))
               else Lexer.Buffer_Text (Name_Region));

            Matching_Name_Index := Matching_Name_Index + 1;
         end;
      end loop;
   end Find_Matching_Name;

   procedure Find_Matching_Name
     (Config              : in     Configuration;
      Lexer               : access constant WisiToken.Lexer.Instance'Class;
      Name                : in     String;
      Matching_Name_Index : in out SAL.Peek_Type;
      Other_ID            : in     Token_ID;
      Other_Count         :    out Integer;
      Case_Insensitive    : in     Boolean)
   is
      use Ada.Characters.Handling;
      Match_Name : constant String := (if Case_Insensitive then To_Lower (Name) else Name);
   begin
      Other_Count := 0;

      loop
         exit when Matching_Name_Index >= Config.Stack.Depth; -- Depth has Invalid_Token_ID
         declare
            Token       : Recover_Token renames Config.Stack.Peek (Matching_Name_Index).Token;
            Name_Region : constant Buffer_Region :=
              (if Token.Name = Null_Buffer_Region
               then Token.Byte_Region
               else Token.Name);
         begin
            exit when Name_Region /= Null_Buffer_Region and then
              Match_Name =
              (if Case_Insensitive
               then To_Lower (Lexer.Buffer_Text (Name_Region))
               else Lexer.Buffer_Text (Name_Region));

            if Other_ID = Token.ID then
               Other_Count := Other_Count + 1;
            end if;

            Matching_Name_Index := Matching_Name_Index + 1;
         end;
      end loop;
   end Find_Matching_Name;

   procedure Insert (Config : in out Configuration; ID : in Token_ID)
   is begin
      Insert (Config, Config.Current_Shared_Token, ID);
   end Insert;

   procedure Insert (Config : in out Configuration; IDs : in Token_ID_Array)
   is begin
      for ID of IDs loop
         Insert (Config, ID);
      end loop;
   end Insert;

   procedure Insert (Config : in out Configuration; Index : in WisiToken.Token_Index; ID : in Token_ID)
   is
      use Config_Op_Arrays;
      use Sorted_Insert_Delete_Arrays;
      Op : constant Config_Op := (Insert, ID, Index, Unknown_State, 0);
   begin
      if Is_Full (Config.Ops) or Is_Full (Config.Insert_Delete) then
         raise Bad_Config;
      end if;
      Append (Config.Ops, Op);
      Insert (Config.Insert_Delete, Op);
      Config.Current_Insert_Delete := 1;
   end Insert;

   function Next_Token
     (Terminals                 :         in     Base_Token_Arrays.Vector;
      Terminals_Current         :         in out Base_Token_Index;
      Restore_Terminals_Current :         in out WisiToken.Base_Token_Index;
      Insert_Delete             : aliased in out Sorted_Insert_Delete_Arrays.Vector;
      Current_Insert_Delete     :         in out SAL.Base_Peek_Type;
      Prev_Deleted              :         in     Recover_Token_Index_Arrays.Vector)
     return Base_Token
   is
      use Sorted_Insert_Delete_Arrays, Insert_Delete_Array_Refs;

      function Next_Terminal return Base_Token
      is begin
         Terminals_Current    := Terminals_Current + 1;
         loop
            exit when not Prev_Deleted.Contains (Terminals_Current);
            Terminals_Current := Terminals_Current + 1;
         end loop;

         Restore_Terminals_Current := Terminals_Current;
         return Terminals (Terminals_Current);
      end Next_Terminal;

   begin
      loop
         if Last_Index (Insert_Delete) > 0 and then Current_Insert_Delete = Last_Index (Insert_Delete) then
            Current_Insert_Delete := No_Insert_Delete;
            Clear (Insert_Delete);
            return Next_Terminal;

         elsif Current_Insert_Delete = No_Insert_Delete then
            return Next_Terminal;

         elsif Token_Index (Constant_Ref (Insert_Delete, Current_Insert_Delete + 1)) = Terminals_Current + 1 then
            Current_Insert_Delete := Current_Insert_Delete + 1;
            declare
               Op : Insert_Delete_Op renames Constant_Ref (Insert_Delete, Current_Insert_Delete);
            begin
               case Insert_Delete_Op_Label'(Op.Op) is
               when Insert =>
                  return (ID => Op.Ins_ID, others => <>);

               when Delete =>
                  Terminals_Current         := Terminals_Current + 1;
                  Restore_Terminals_Current := Terminals_Current;
               end case;
            end;

         else
            return Next_Terminal;
         end if;
      end loop;
   end Next_Token;

   procedure Push_Back (Config : in out Configuration)
   is
      use Config_Op_Arrays, Config_Op_Array_Refs;
      use Sorted_Insert_Delete_Arrays;

      Item        : constant Recover_Stack_Item := Config.Stack.Pop;
      Token_Index : constant Base_Token_Index   := Item.Token.Min_Terminal_Index;

      function Compare (Left : in Base_Token_Index; Right : in Config_Op) return Boolean
        is (case Right.Op is
            when Fast_Forward    => False,
            when Undo_Reduce     => False,
            when Push_Back       => False,
            when Insert => Left < Right.Ins_Token_Index,
            when Delete => Left < Right.Del_Token_Index);
      --  If Left = Right.Token_Index, we assume the Right ops go _after_
      --  the Left, so the Left do not need to be repeated.
   begin
      if Token_Index /= Invalid_Token_Index then
         Config.Current_Shared_Token := Token_Index;
         for I in First_Index (Config.Ops) .. Last_Index (Config.Ops) loop
            if Compare (Token_Index, Constant_Ref (Config.Ops, I)) then
               if Is_Full (Config.Insert_Delete) then
                  raise Bad_Config;
               end if;
               Insert (Config.Insert_Delete, Constant_Ref (Config.Ops, I), Ignore_If_Equal => True);
            end if;
         end loop;
      end if;

      if Is_Full (Config.Ops) then
         raise Bad_Config;
      end if;
      Append (Config.Ops, (Push_Back, Item.Token.ID, Config.Current_Shared_Token));
   end Push_Back;

   procedure Push_Back_Check (Config : in out Configuration; Expected_ID : in Token_ID)
   is begin
      pragma Assert (Config.Stack.Depth > 1);
      Check (Config.Stack.Peek (1).Token.ID, Expected_ID);
      Push_Back (Config);
   end Push_Back_Check;

   procedure Push_Back_Check (Config : in out Configuration; Expected : in Token_ID_Array)
   is begin
      for ID of Expected loop
         Push_Back_Check (Config, ID);
      end loop;
   end Push_Back_Check;

   procedure Put
     (Message      : in     String;
      Trace        : in out WisiToken.Trace'Class;
      Parser_Label : in     Natural;
      Terminals    : in     Base_Token_Arrays.Vector;
      Config       : in     Configuration;
      Task_ID      : in     Boolean := True;
      Strategy     : in     Boolean := False)
   is
      --  For debugging output

      --  Build a string, call trace.put_line once, so output from multiple
      --  tasks is not interleaved (mostly).
      use Insert_Delete_Array_Refs;
      use all type Ada.Strings.Unbounded.Unbounded_String;
      use all type WisiToken.Semantic_Checks.Check_Status_Label;

      Descriptor : WisiToken.Descriptor renames Trace.Descriptor.all;

      Result : Ada.Strings.Unbounded.Unbounded_String :=
        (if Task_ID then +"task" & Task_Attributes.Value'Image else +"") &
        Integer'Image (Parser_Label) & ": " &
        (if Message'Length > 0 then Message & ":" else "");
   begin
      Result := Result & Natural'Image (Config.Cost);
      if Strategy or Trace_McKenzie > Extra then
         Result := Result & ", (";
         for C of Config.Strategy_Counts loop
            Result := Result & Integer'Image (C);
         end loop;
         Result := Result & "), ";
      else
         Result := Result & ", ";
      end if;
      if Config.Check_Status.Label /= Ok then
         Result := Result & Semantic_Checks.Check_Status_Label'Image (Config.Check_Status.Label) & " ";
      elsif Config.Error_Token.ID /= Invalid_Token_ID then
         Result := Result & "Error " & Image (Config.Error_Token, Descriptor) & " ";
      end if;
      Result := Result & Image (Config.Stack, Descriptor, Depth => 1);

      if Config.Current_Insert_Delete = No_Insert_Delete then
         Result := Result & "|" & Image (Config.Current_Shared_Token, Terminals, Descriptor) & "|";
      else
         Result := Result & "/" & Trimmed_Image (Config.Current_Insert_Delete) & ":" &
           Image (Constant_Ref (Config.Insert_Delete, Config.Current_Insert_Delete), Descriptor) & "/";
      end if;

      Result := Result & Image (Config.Ops, Descriptor);
      if Config.Minimal_Complete_State /= None then
         Result := Result & " minimal_complete " & Config.Minimal_Complete_State'Image;
      end if;
      Trace.Put_Line (-Result);
   end Put;

   procedure Put_Line
     (Trace        : in out WisiToken.Trace'Class;
      Parser_Label : in     Natural;
      Message      : in     String;
      Task_ID      : in     Boolean := True)
   is begin
      Trace.Put_Line
        ((if Task_ID then "task" & Task_Attributes.Value'Image else "") &
           Integer'Image (Parser_Label) & ": " & Message);
   end Put_Line;

   function Undo_Reduce
     (Stack : in out Recover_Stacks.Stack;
      Tree  : in     Syntax_Trees.Tree)
     return Ada.Containers.Count_Type
   is
      Nonterm_Item : constant Recover_Stack_Item := Recover_Stacks.Pop (Stack);
   begin
      if Nonterm_Item.Token.Byte_Region = Null_Buffer_Region then
         return 0;
      end if;
      declare
         Children : constant Syntax_Trees.Valid_Node_Index_Array := Tree.Children (Nonterm_Item.Tree_Index);
      begin
         for C of Children loop
            Stack.Push ((Tree.State (C), C, Tree.Recover_Token (C)));
         end loop;
         return Children'Length;
      end;
   end Undo_Reduce;

   procedure Undo_Reduce_Check
     (Config   : in out Configuration;
      Tree     : in     Syntax_Trees.Tree;
      Expected : in     Token_ID)
   is begin
      pragma Assert (Config.Stack.Depth > 1);
      Check (Config.Stack.Peek (1).Token.ID, Expected);
      Config_Op_Arrays.Append (Config.Ops, (Undo_Reduce, Expected, Undo_Reduce (Config.Stack, Tree)));
   exception
   when SAL.Container_Full =>
      raise Bad_Config;
   end Undo_Reduce_Check;

   procedure Undo_Reduce_Check
     (Config   : in out Configuration;
      Tree     : in     Syntax_Trees.Tree;
      Expected : in     Token_ID_Array)
   is begin
      for ID of Expected loop
         Undo_Reduce_Check (Config, Tree, ID);
      end loop;
   end Undo_Reduce_Check;

end WisiToken.Parse.LR.McKenzie_Recover;
