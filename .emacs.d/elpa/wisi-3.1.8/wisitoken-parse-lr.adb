--  Abstract :
--
--  See spec.
--
--  Copyright (C) 2013-2015, 2017 - 2022 Free Software Foundation, Inc.
--
--  This file is part of the WisiToken package.
--
--  The WisiToken package is free software; you can redistribute it
--  and/or modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation; either version 3, or
--  (at your option) any later version. The WisiToken package is
--  distributed in the hope that it will be useful, but WITHOUT ANY
--  WARRANTY; without even the implied warranty of MERCHANTABILITY or
--  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
--  License for more details. You should have received a copy of the
--  GNU General Public License distributed with the WisiToken package;
--  see file GPL.txt. If not, write to the Free Software Foundation,
--  59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
--
--  As a special exception, if other files instantiate generics from
--  this unit, or you link this unit with other files to produce an
--  executable, this unit does not by itself cause the resulting
--  executable to be covered by the GNU General Public License. This
--  exception does not however invalidate any other reasons why the
--  executable file might be covered by the GNU Public License.

pragma License (GPL);

with Ada.Characters.Handling;
with Ada.Exceptions;
with Ada.Strings.Fixed;
with Ada.Strings.Maps;
with Ada.Text_IO;
with GNATCOLL.Mmap;
package body WisiToken.Parse.LR is

   ----------
   --  Public subprograms, declaration order

   function Image (Item : in Parse_Action_Rec; Descriptor : in WisiToken.Descriptor) return String
   is
      use Ada.Containers;
   begin
      case Item.Verb is
      when Shift =>
         return "(Shift," & State_Index'Image (Item.State) & ")";

      when Reduce =>
         return "(Reduce," & Count_Type'Image (Item.Token_Count) & ", " &
           Image (Item.Production.LHS, Descriptor) & "," & Trimmed_Image (Item.Production.RHS) & ")";
      when Accept_It =>
         return "(Accept It)";
      when Error =>
         return "(Error)";
      end case;
   end Image;

   function Trace_Image (Item : in Parse_Action_Rec; Descriptor : in WisiToken.Descriptor) return String
   is begin
      case Item.Verb is
      when Shift =>
         return "shift and goto state" &
           (if Trace_Parse_No_State_Numbers
            then " --"
            else State_Index'Image (Item.State));

      when Reduce =>
         return "reduce" & Item.Token_Count'Image  & " tokens to " &
           Image (Item.Production.LHS, Descriptor);

      when Accept_It =>
         return "accept it";

      when Error =>
         return "ERROR";
      end case;
   end Trace_Image;

   function Equal (Left, Right : in Parse_Action_Rec) return Boolean
   is
      use all type Ada.Containers.Count_Type;
   begin
      if Left.Verb = Right.Verb then
         case Left.Verb is
         when Shift =>
            return Left.State = Right.State;

         when Reduce | Accept_It =>
            return Left.Production.LHS = Right.Production.LHS and Left.Token_Count = Right.Token_Count;

         when Error =>
            return True;
         end case;
      else
         return False;
      end if;
   end Equal;

   function Is_In (Item : in Parse_Action_Rec; List : in Parse_Action_Node_Ptr) return Boolean
   is
      Node : Parse_Action_Node_Ptr := List;
   begin
      loop
         exit when Node = null;
         if Equal (Item, Node.Item) then
            return True;
         end if;
         Node := Node.Next;
      end loop;
      return False;
   end Is_In;

   procedure Delete
     (Container : in out Action_Node;
      Prev      : in     Parse_Action_Node_Ptr;
      Current   : in out Parse_Action_Node_Ptr)
   is
      To_Delete : Parse_Action_Node_Ptr := Current;
   begin
      Current := Current.Next;
      if Container.Actions = To_Delete then
         Container.Actions := Current;
      else
         Prev.Next := Current;
      end if;
      Free (To_Delete);
   end Delete;

   procedure Add
     (List   : in out Action_Arrays.Vector;
      Symbol : in     Token_ID;
      Action : in     Parse_Action_Rec)
   is begin
      declare
         Node : constant Action_Arrays.Find_Reference_Type := List.Find (Symbol);
      begin
         if Node.Element /= null then
            declare
               I : Parse_Action_Node_Ptr := Node.Element.Actions;
            begin
               loop
                  exit when I.Next = null;
                  I := I.Next;
               end loop;
               I.Next := new Parse_Action_Node'(Action, null);
               return;
            end;
         end if;
      end;
      List.Insert ((Symbol, new Parse_Action_Node'(Action, null)));
   end Add;

   function To_Vector (Item : in Kernel_Info_Array) return Kernel_Info_Arrays.Vector
   is begin
      return Result : Kernel_Info_Arrays.Vector do
         Result.Set_First_Last (Item'First, Item'Last);
         for I in Item'Range loop
            Result (I) := Item (I);
         end loop;
      end return;
   end To_Vector;

   function Strict_Image (Item : in Kernel_Info) return String
   is begin
      return "(" & Image (Item.Production) & ", " &
        Item.Before_Dot'Image & ", " &
        Item.Length_After_Dot'Image & ", " &
        Image (Item.Reduce_Production) & ", " &
        Item.Reduce_Count'Image & ")";
   end Strict_Image;

   function Image (Item : in Kernel_Info; Descriptor : in WisiToken.Descriptor) return String
   is begin
      return "(" & Image (Item.Production, Descriptor) & ", " &
        Item.Length_After_Dot'Image & ", " &
        Image (Item.Reduce_Production, Descriptor) & ", " &
        Item.Reduce_Count'Image & ")";
   end Image;

   function Strict_Image (Item : in Minimal_Action) return String
   is begin
      case Item.Verb is
      when Shift =>
         return "(Shift, " & Image (Item.Production) & ", " &
           Token_ID'Image (Item.ID) & "," & State_Index'Image (Item.State) & ")";

      when Reduce =>
         return "(Reduce, " & Image (Item.Production) & ", " &
           Ada.Containers.Count_Type'Image (Item.Token_Count) & ")";
      end case;
   end Strict_Image;

   function Image (Item : in Minimal_Action; Descriptor : in WisiToken.Descriptor) return String
   is begin
      case Item.Verb is
      when Shift =>
         return "Shift " & Image (Item.ID, Descriptor);
      when Reduce =>
         return "Reduce" & Item.Token_Count'Image & " tokens to " & Image (Item.Production.LHS, Descriptor);
      end case;
   end Image;

   function To_Vector (Item : in Minimal_Action_Array) return Minimal_Action_Arrays.Vector
   is begin
      return Result : Minimal_Action_Arrays.Vector do
         Result.Set_First_Last (Item'First, Item'Last);
         for I in Item'Range loop
            Result.Replace_Element (I, Item (I));
         end loop;
      end return;
   end To_Vector;

   procedure Add_Action
     (State       : in out LR.Parse_State;
      Symbol      : in     Token_ID;
      Production  : in     Production_ID;
      State_Index : in     WisiToken.State_Index)
   is begin
      Add (State.Action_List, Symbol, (Shift, Production, State_Index));
   end Add_Action;

   procedure Add_Action
     (State           : in out LR.Parse_State;
      Symbol          : in     Token_ID;
      Verb            : in     LR.Parse_Action_Verbs;
      Production      : in     Production_ID;
      RHS_Token_Count : in     Ada.Containers.Count_Type)
   is
      Action : constant Parse_Action_Rec :=
        (case Verb is
         when Reduce    => (Reduce, Production, RHS_Token_Count),
         when Accept_It => (Accept_It, Production, RHS_Token_Count),
         when others    => raise SAL.Programmer_Error);
   begin
      Add (State.Action_List, Symbol, Action);
   end Add_Action;

   procedure Add_Action
     (State             : in out Parse_State;
      Symbols           : in     Token_ID_Array;
      Production        : in     Production_ID;
      RHS_Token_Count   : in     Ada.Containers.Count_Type)
   is begin
      --  We assume WisiToken.BNF.Output_Ada_Common.Duplicate_Reduce is True
      --  for this state; no conflicts, all the same action, Recursive.
      for Symbol of Symbols loop
         Add_Action (State, Symbol, Reduce, Production, RHS_Token_Count);
      end loop;
   end Add_Action;

   procedure Add_Conflict
     (State             : in out LR.Parse_State;
      Symbol            : in     Token_ID;
      Reduce_Production : in     Production_ID;
      RHS_Token_Count   : in     Ada.Containers.Count_Type)
   is
      Conflict : constant Parse_Action_Rec := (Reduce, Reduce_Production, RHS_Token_Count);

      Ref : constant Action_Arrays.Find_Reference_Constant_Type := State.Action_List.Find_Constant (Symbol);

      Node : Parse_Action_Node_Ptr := Ref.Actions;
   begin
      loop
         exit when Node.Next = null;
         Node := Node.Next;
      end loop;
      Node.Next := new Parse_Action_Node'(Conflict, null);
   end Add_Conflict;

   procedure Add_Goto
     (State      : in out LR.Parse_State;
      Symbol     : in     Token_ID;
      To_State   : in     State_Index)
   is begin
      State.Goto_List.Insert ((Symbol, To_State));
   end Add_Goto;

   procedure Set_McKenzie_Options (Param : in out McKenzie_Param_Type; Config : in String)
   is
      use Ada.Characters.Handling;
      use Ada.Strings.Fixed;
      Name_First : Integer := Config'First;
      Name_Last  : Integer;

      Value_First : Integer;
      Value_Last  : Integer;
   begin
      loop
         Name_Last := Index (Config, "=", Name_First);
         exit when Name_Last = 0;

         Value_First := Name_Last + 1;
         Name_Last   := Name_Last - 1;
         Value_Last  := Index (Config, " ", Value_First);
         if Value_Last = 0 then
            Value_Last := Config'Last;
         end if;
         declare
            Name : constant String := To_Lower (Config (Name_First .. Name_Last));

            function Get_Value return Integer
            is begin
               return Integer'Value (Config (Value_First .. Value_Last));
            exception
            when Constraint_Error =>
               raise User_Error with "expecting integer value, found '" &
                 Config (Value_First .. Value_Last) & "'";
            end Get_Value;

            Value : constant Integer := Get_Value;
         begin
            --  Trace var alphabetical order
            if Name = "check_delta_limit" or
              Name = "check_delta"
            then
               Param.Check_Delta_Limit := Value;

            elsif Name = "check_limit" then
               Param.Check_Limit := Syntax_Trees.Sequential_Index (Value);

            elsif Name = "enqueue_limit" then
               Param.Enqueue_Limit := Value;

            elsif Name = "zombie_limit" then
               Param.Zombie_Limit := Value;

            else
               raise User_Error with "expecting McKenzie option name, found '" & Config (Name_First .. Name_Last) & "'";
            end if;
         end;

         Name_First := Value_Last + 1;
         exit when Name_First > Config'Last;
      end loop;
   end Set_McKenzie_Options;

   function Goto_For
     (Table : in Parse_Table;
      State : in State_Index;
      ID    : in Token_ID)
     return Unknown_State_Index
   is
      Ref : constant Goto_Arrays.Find_Reference_Constant_Type := Table.States (State).Goto_List.Find_Constant (ID);
   begin
      if Ref.Element = null then
         --  We can only get here during error recovery.
         return Unknown_State;
      else
         return Ref.State;
      end if;
   end Goto_For;

   function Action_For
     (Table : in Parse_Table;
      State : in State_Index;
      ID    : in Token_ID)
     return Parse_Action_Node_Ptr
   is
      Ref : constant Action_Arrays.Find_Reference_Constant_Type := Table.States (State).Action_List.Find_Constant (ID);
   begin
      if Ref.Element = null then
         return Table.Error_Action;
      end if;

      return Ref.Actions;
   end Action_For;

   function Shift_State (Action_List : in Parse_Action_Node_Ptr) return State_Index
   is begin
      --  There can be only one shift action, and it is always first.
      return Action_List.Item.State;
   end Shift_State;

   procedure Undo_Reduce
     (Tree      : in out Syntax_Trees.Tree;
      Table     : in     Parse_Table;
      Stream    : in     Syntax_Trees.Stream_ID;
      User_Data : in     Syntax_Trees.User_Data_Access_Constant)
   is
      --  We can't move this into Syntax_Trees, because we need Table to set
      --  the stream element states.
      use Syntax_Trees;
   begin
      if Tree.Has_Error (Tree.Get_Node (Stream, Tree.Peek (Stream))) then
         --  Move the errors to the first terminal, so they are not lost.
         declare
            Ref : Stream_Node_Parents := Tree.To_Stream_Node_Parents
              (Tree.To_Rooted_Ref (Stream, Tree.Peek (Stream)));

            New_Errors : Error_Data_Lists.List;
         begin
            for Err of Tree.Error_List (Ref.Ref.Node) loop
               New_Errors.Append (To_Message (Err, Tree, Ref.Ref.Node));
            end loop;

            Tree.First_Terminal (Ref, Following => False);
            if Ref.Ref.Node = Invalid_Node_Access then
               --  So far, we never put an error on an empty nonterm; we just delete
               --  it.
               raise SAL.Programmer_Error with "undo_reduce error on empty nonterm";
            end if;
            Tree.Add_Errors (Ref, New_Errors, User_Data);
         end;
      end if;

      declare
         Nonterm    : constant Node_Access := Tree.Pop (Stream);
         Prev_State : State_Index          := Tree.State (Stream);
      begin
         for Child of Tree.Children (Nonterm) loop
            Tree.Clear_Parent (Child, Clear_Children => Stream = Tree.Shared_Stream);

            if Is_Terminal (Tree.ID (Child), Tree.Lexer.Descriptor.all) then
               Prev_State := Shift_State (Action_For (Table, Prev_State, Tree.ID (Child)));
            else
               Prev_State := Goto_For (Table, Prev_State, Tree.ID (Child));
            end if;
            Tree.Push (Stream, Child, Prev_State);
         end loop;
      end;
   end Undo_Reduce;

   function Expecting (Table : in Parse_Table; State : in State_Index) return Token_ID_Set
   is
      Result : Token_ID_Set := (Table.First_Terminal .. Table.Last_Terminal => False);
   begin
      for Action of Table.States (State).Action_List loop
         Result (Action.Symbol) := True;
      end loop;
      return Result;
   end Expecting;

   procedure Free_Table (Table : in out Parse_Table_Ptr)
   is
      procedure Free is new Ada.Unchecked_Deallocation (Parse_Table, Parse_Table_Ptr);
      Parse_Action      : Parse_Action_Node_Ptr;
      Temp_Parse_Action : Parse_Action_Node_Ptr;
   begin
      if Table = null then
         return;
      end if;

      for State of Table.States loop
         for Action of State.Action_List loop
            Parse_Action := Action.Actions;
            loop
               exit when Parse_Action = null;
               Temp_Parse_Action := Parse_Action;
               Parse_Action := Parse_Action.Next;
               Free (Temp_Parse_Action);
            end loop;
         end loop;
      end loop;

      Free (Table);
   end Free_Table;

   function Get_Text_Rep (File_Name : in String) return Parse_Table_Ptr
   is
      use Ada.Text_IO;

      File            : GNATCOLL.Mmap.Mapped_File;
      Region          : GNATCOLL.Mmap.Mapped_Region;
      Buffer          : GNATCOLL.Mmap.Str_Access;
      Buffer_Abs_Last : Integer; --  Buffer'Last, except Buffer has no bounds
      Buffer_Last     : Integer := 0; -- Last char read from Buffer

      Delimiters : constant Ada.Strings.Maps.Character_Set := Ada.Strings.Maps.To_Set (" ;" & ASCII.LF);

      function Check_Semicolon return Boolean
      is begin
         if Buffer (Buffer_Last) = ';' then
            --  There is a space, newline, or newline and space after ';'. Leave
            --  Buffer_Last on newline for Check_New_Line.
            Buffer_Last := Buffer_Last + 1;
            return True;
         else
            return False;
         end if;
      end Check_Semicolon;

      procedure Check_Semicolon
      is begin
         if Buffer (Buffer_Last) = ';' then
            --  There is a space, newline, or newline and space after ';'. Leave
            --  Buffer_Last on newline for Check_New_Line.
            Buffer_Last := Buffer_Last + 1;
         else
            raise SAL.Programmer_Error with WisiToken.Error_Message
              (File_Name, 1, Ada.Text_IO.Count (Buffer_Last),
               "expecting semicolon, found '" & Buffer (Buffer_Last) & "'");
         end if;
      end Check_Semicolon;

      function Check_EOI return Boolean
      is begin
         return Buffer_Last >= Buffer_Abs_Last;
      end Check_EOI;

      procedure Check_New_Line
      is
         use Ada.Strings.Maps;
      begin
         if Buffer (Buffer_Last) = ASCII.LF then
            --  There is a space or semicolon after some newlines.
            if Is_In (Buffer (Buffer_Last + 1), Delimiters) then
               Buffer_Last := Buffer_Last + 1;
            end if;
         else
            raise SAL.Programmer_Error with WisiToken.Error_Message
              (File_Name, 1, Ada.Text_IO.Count (Buffer_Last),
               "expecting new_line, found '" & Buffer (Buffer_Last) & "'");
         end if;
      end Check_New_Line;

      type Buffer_Region is record
         First : Integer;
         Last  : Integer;
      end record;

      function Next_Value return Buffer_Region;
      pragma Inline (Next_Value);

      function Next_Value return Buffer_Region
      is
         use Ada.Strings.Fixed;
         First : constant Integer := Buffer_Last + 1;
      begin
         Buffer_Last := Index (Buffer.all, Delimiters, First);
         return (First, Buffer_Last - 1);
      end Next_Value;

      procedure Raise_Gen_Next_Value_Constraint_Error (Name : String; Region : Buffer_Region);
      pragma No_Return (Raise_Gen_Next_Value_Constraint_Error);

      procedure Raise_Gen_Next_Value_Constraint_Error (Name : String; Region : Buffer_Region)
      is begin
         --  Factored out from Gen_Next_Value to make Inline efficient.
         raise SAL.Programmer_Error with WisiToken.Error_Message
           (File_Name, 1, Ada.Text_IO.Count (Region.First),
            "expecting " & Name & ", found '" & Buffer (Region.First .. Region.Last) & "'");
      end Raise_Gen_Next_Value_Constraint_Error;

      generic
         type Value_Type is (<>);
         Name : in String;
      function Gen_Next_Value return Value_Type;
      pragma Inline (Gen_Next_Value);

      function Gen_Next_Value return Value_Type
      is
         Region : constant Buffer_Region := Next_Value;
      begin
         return Value_Type'Value (Buffer (Region.First .. Region.Last));
      exception
      when Constraint_Error =>
         Raise_Gen_Next_Value_Constraint_Error (Name, Region);
      end Gen_Next_Value;

      function Next_State_Index is new Gen_Next_Value (State_Index, "State_Index");
      function Next_Token_ID is new Gen_Next_Value (Token_ID, "Token_ID");
      function Next_Integer is new Gen_Next_Value (Integer, "Integer");
      function Next_Parse_Action_Verbs is new Gen_Next_Value (Parse_Action_Verbs, "Parse_Action_Verbs");
      function Next_Count_Type is new Gen_Next_Value (Ada.Containers.Count_Type, "Count_Type");
   begin
      File            := GNATCOLL.Mmap.Open_Read (File_Name);
      Region          := GNATCOLL.Mmap.Read (File);
      Buffer          := GNATCOLL.Mmap.Data (Region);
      Buffer_Abs_Last := GNATCOLL.Mmap.Last (Region);

      declare
         use Ada.Containers;

         --  We don't read the discriminants in the aggregate, because
         --  aggregate evaluation order is not guaranteed.
         State_First       : constant State_Index := Next_State_Index;
         State_Last        : constant State_Index := Next_State_Index;
         First_Terminal    : constant Token_ID    := Next_Token_ID;
         Last_Terminal     : constant Token_ID    := Next_Token_ID;
         First_Nonterminal : constant Token_ID    := Next_Token_ID;
         Last_Nonterminal  : constant Token_ID    := Next_Token_ID;

         Table : constant Parse_Table_Ptr := new Parse_Table
           (State_First, State_Last, First_Terminal, Last_Terminal, First_Nonterminal, Last_Nonterminal);
      begin
         Check_New_Line;

         for State of Table.States loop
            declare
               Actions_Done : Boolean := False;
            begin
               State.Action_List.Set_Capacity (Next_Count_Type);

               loop
                  declare
                     Node_I      : Action_Node;
                     Node_J      : Parse_Action_Node_Ptr := new Parse_Action_Node;
                     Action_Done : Boolean               := False;
                     Verb        : Parse_Action_Verbs;
                  begin
                     Node_I.Actions := Node_J;
                     loop
                        Verb := Next_Parse_Action_Verbs;
                        Node_J.Item :=
                          (case Verb is
                           when Shift     => (Verb => Shift, others => <>),
                           when Reduce    => (Verb => Reduce, others => <>),
                           when Accept_It => (Verb => Accept_It, others => <>),
                           when Error     => (Verb => Error, others => <>));

                        Node_J.Item.Production.LHS := Next_Token_ID;
                        Node_J.Item.Production.RHS := Next_Integer;

                        case Verb is
                        when Shift =>
                           Node_J.Item.State := Next_State_Index;

                        when Reduce | Accept_It =>
                           Node_J.Item.Token_Count := Next_Count_Type;

                        when Error =>
                           raise SAL.Programmer_Error;
                        end case;

                        if Check_Semicolon then
                           Action_Done := True;

                           Node_I.Symbol := Next_Token_ID;

                           if Check_Semicolon then
                              Actions_Done := True;
                           end if;
                        end if;

                        exit when Action_Done;

                        Node_J.Next := new Parse_Action_Node;
                        Node_J      := Node_J.Next;
                     end loop;

                     Check_New_Line;
                     State.Action_List.Insert (Node_I);
                  end;

                  exit when Actions_Done;
               end loop;
            end;

            if Check_Semicolon then
               --  No Gotos
               null;
            else
               State.Goto_List.Set_Capacity (Next_Count_Type);
               declare
                  Node : Goto_Node;
               begin
                  loop
                     Node.Symbol := Next_Token_ID;
                     Node.State  := Next_State_Index;
                     State.Goto_List.Insert (Node);
                     exit when Check_Semicolon;
                  end loop;
               end;
            end if;
            Check_New_Line;

            declare
               First : constant Count_Type := Next_Count_Type;
               Last  : constant Integer    := Next_Integer;
            begin
               if Last = -1 then
                  --  State.Kernel not set for state 0
                  null;
               else
                  State.Kernel.Set_First_Last (First, Count_Type (Last));

                  for I in State.Kernel.First_Index .. State.Kernel.Last_Index loop
                     State.Kernel (I).Production.LHS        := Next_Token_ID;
                     State.Kernel (I).Production.RHS        := Next_Integer;
                     State.Kernel (I).Before_Dot            := Next_Token_ID;
                     State.Kernel (I).Length_After_Dot      := Next_Count_Type;
                     State.Kernel (I).Reduce_Production.LHS := Next_Token_ID;
                     State.Kernel (I).Reduce_Production.RHS := Next_Integer;
                     State.Kernel (I).Reduce_Count          := Next_Count_Type;
                  end loop;
               end if;
            end;
            Check_New_Line;

            if Check_Semicolon then
               --  No minimal action
               null;
            else
               declare
                  First : constant Count_Type := Next_Count_Type;
                  Last  : constant Count_Type := Next_Count_Type;
               begin
                  State.Minimal_Complete_Actions.Set_First_Last (First, Last);
               end;
               for I in State.Minimal_Complete_Actions.First_Index .. State.Minimal_Complete_Actions.Last_Index loop
                  declare
                     Verb         : constant Minimal_Verbs := Next_Parse_Action_Verbs;
                     LHS          : Token_ID;
                     RHS          : Integer;
                     ID           : Token_ID;
                     Action_State : State_Index;
                     Count        : Ada.Containers.Count_Type;
                  begin
                     LHS := Next_Token_ID;
                     RHS := Next_Integer;
                     case Verb is
                     when Shift =>
                        ID           := Next_Token_ID;
                        Action_State := Next_State_Index;
                        State.Minimal_Complete_Actions.Replace_Element (I, (Shift, (LHS, RHS), ID, Action_State));
                     when Reduce =>
                        Count := Next_Count_Type;
                        State.Minimal_Complete_Actions.Replace_Element (I, (Reduce, (LHS, RHS), Count));
                     end case;
                  end;
               end loop;
               Check_Semicolon;
            end if;
            Check_New_Line;

            exit when Check_EOI;
         end loop;

         Table.Error_Action := new Parse_Action_Node'((Verb => Error, others => <>), null);

         return Table;
      end;
   exception
   when Name_Error =>
      raise User_Error with "parser table text file '" & File_Name & "' not found.";

   when SAL.Programmer_Error =>
      raise;

   when E : others =>
      raise SAL.Programmer_Error with WisiToken.Error_Message
        (File_Name, 1, Ada.Text_IO.Count (Buffer_Last),
         Ada.Exceptions.Exception_Name (E) & ": " & Ada.Exceptions.Exception_Message (E));
   end Get_Text_Rep;

   function Stack_Has
     (Tree  : in Syntax_Trees.Tree;
      Stack : in Recover_Stacks.Stack;
      ID    : in Token_ID)
     return Boolean
   is
      use Recover_Stacks;
   begin
      for I in 1 .. Depth (Stack) loop
         if Tree.Element_ID (Peek (Stack, I).Token) = ID then
            return True;
         end if;
      end loop;
      return False;
   end Stack_Has;

   function Valid_Tree_Indices (Stack : in Recover_Stacks.Stack; Depth : in SAL.Base_Peek_Type) return Boolean
   is begin
      for I in 1 .. Depth loop
         if Stack.Peek (I).Token.Virtual then
            return False;
         end if;
      end loop;
      return True;
   end Valid_Tree_Indices;

   procedure Set_Key (Item : in out Configuration; Key : in Integer)
   is begin
      Item.Cost := Key;
   end Set_Key;

   procedure Accumulate (Data : in McKenzie_Data; Counts : in out Strategy_Counts)
   is
      procedure Proc (Config : in Configuration)
      is begin
         for I in Config.Strategy_Counts'Range loop
            Counts (I) := Counts (I) + Config.Strategy_Counts (I);
         end loop;
      end Proc;
   begin
      Data.Results.Process (Proc'Unrestricted_Access);
   end Accumulate;

end WisiToken.Parse.LR;
