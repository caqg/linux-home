--  Abstract :
--
--  See spec.
--
--  Copyright (C) 2013-2015, 2017, 2018, 2019 Free Software Foundation, Inc.
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

with Ada.Exceptions;
with Ada.Strings.Maps;
with Ada.Strings.Fixed;
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

   procedure Put (Trace : in out WisiToken.Trace'Class; Item : in Parse_Action_Rec)
   is
      use Ada.Containers;
   begin
      case Item.Verb is
      when Shift =>
         Trace.Put ("shift and goto state" & State_Index'Image (Item.State), Prefix => False);

      when Reduce =>
         Trace.Put
           ("reduce" & Count_Type'Image (Item.Token_Count) & " tokens to " &
              Image (Item.Production.LHS, Trace.Descriptor.all),
            Prefix => False);
      when Accept_It =>
         Trace.Put ("accept it", Prefix => False);
      when Error =>
         Trace.Put ("ERROR", Prefix => False);
      end case;
   end Put;

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

   function Find
     (Symbol      : in Token_ID;
      Action_List : in Action_Node_Ptr)
     return Action_Node_Ptr
   is
      Action_Node : Action_Node_Ptr := Action_List;
   begin
      while Action_Node /= null loop
         if Action_Node.Symbol = Symbol then
            return Action_Node;
         end if;
         Action_Node := Action_Node.Next;
      end loop;

      return null;
   end Find;

   procedure Add
     (List   : in out Action_Node_Ptr;
      Symbol : in     Token_ID;
      Action : in     Parse_Action_Rec)
   is
      New_Item : constant Action_Node_Ptr := new Action_Node'(Symbol, new Parse_Action_Node'(Action, null), null);
      I        : Action_Node_Ptr          := List;
   begin
      if I = null then
         List := New_Item;
      else
         if List.Symbol > Symbol then
            New_Item.Next := List;
            List          := New_Item;
         else
            if List.Next = null then
               List.Next := New_Item;
            else
               I := List;
               loop
                  exit when I.Next = null or else I.Next.Symbol > Symbol;
                  I := I.Next;
               end loop;
               New_Item.Next := I.Next;
               I.Next        := New_Item;
            end if;
         end if;
      end if;
   end Add;

   function Symbol (List : in Goto_Node_Ptr) return Token_ID
   is begin
      return List.Symbol;
   end Symbol;

   function State (List : in Goto_Node_Ptr) return State_Index
   is begin
      return List.State;
   end State;

   function Next (List : in Goto_Node_Ptr) return Goto_Node_Ptr
   is begin
      return List.Next;
   end Next;

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
      return "(" & Trimmed_Image (Item.LHS) & "," & Token_ID'Image (Item.Before_Dot) & "," &
        Ada.Containers.Count_Type'Image (Item.Length_After_Dot) & ", " &
        (if Item.Recursive then "True" else "False") & ")";
   end Strict_Image;

   function Strict_Image (Item : in Minimal_Action) return String
   is begin
      case Item.Verb is
      when Shift =>
         return "(Shift," & Token_ID'Image (Item.ID) & "," & State_Index'Image (Item.State) & ")";
      when Reduce =>
         return "(Reduce," & Token_ID'Image (Item.Nonterm) & "," &
           Ada.Containers.Count_Type'Image (Item.Token_Count) & ")";
      end case;
   end Strict_Image;

   function Image (Item : in Minimal_Action; Descriptor : in WisiToken.Descriptor) return String
   is begin
      case Item.Verb is
      when Shift =>
         return "Shift " & Image (Item.ID, Descriptor);
      when Reduce =>
         return "Reduce to " & Image (Item.Nonterm, Descriptor);
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

   function First (State : in Parse_State) return Action_List_Iterator
   is begin
      return Iter : Action_List_Iterator := (Node => State.Action_List, Item => null) do
         loop
            exit when Iter.Node = null;
            Iter.Item := Iter.Node.Action;
            exit when Iter.Item /= null;
            Iter.Node := Iter.Node.Next;
         end loop;
      end return;
   end First;

   function Is_Done (Iter : in Action_List_Iterator) return Boolean
   is begin
      return Iter.Node = null;
   end Is_Done;

   procedure Next (Iter : in out Action_List_Iterator)
   is begin
      if Iter.Node = null then
         return;
      end if;

      if Iter.Item.Next = null then
         loop
            Iter.Node := Iter.Node.Next;
            exit when Iter.Node = null;
            Iter.Item := Iter.Node.Action;
            exit when Iter.Item /= null;
         end loop;
      else
         Iter.Item := Iter.Item.Next; -- a conflict
      end if;
   end Next;

   function Symbol (Iter : in Action_List_Iterator) return Token_ID
   is begin
      return Iter.Node.Symbol;
   end Symbol;

   function Action (Iter : in Action_List_Iterator) return Parse_Action_Rec
   is begin
      return Iter.Item.Item;
   end Action;

   procedure Add_Action
     (State       : in out LR.Parse_State;
      Symbol      : in     Token_ID;
      State_Index : in     WisiToken.State_Index)
   is
      Action   : constant Parse_Action_Rec := (Shift, State_Index);
      New_Node : constant Action_Node_Ptr  := new Action_Node'(Symbol, new Parse_Action_Node'(Action, null), null);
      Node     : Action_Node_Ptr;
   begin
      if State.Action_List = null then
         State.Action_List := New_Node;
      else
         Node := State.Action_List;
         loop
            exit when Node.Next = null;
            Node := Node.Next;
         end loop;
         Node.Next := New_Node;
      end if;
   end Add_Action;

   procedure Add_Action
     (State           : in out LR.Parse_State;
      Symbol          : in     Token_ID;
      Verb            : in     LR.Parse_Action_Verbs;
      Production      : in     Production_ID;
      RHS_Token_Count : in     Ada.Containers.Count_Type;
      Semantic_Action : in     WisiToken.Syntax_Trees.Semantic_Action;
      Semantic_Check  : in     Semantic_Checks.Semantic_Check)
   is
      Action   : Parse_Action_Rec;
      New_Node : Action_Node_Ptr;
      Node     : Action_Node_Ptr;
   begin
      case Verb is
      when Reduce =>
         Action := (Reduce, Production, Semantic_Action, Semantic_Check, RHS_Token_Count);
      when Accept_It =>
         Action := (Accept_It, Production, Semantic_Action, Semantic_Check, RHS_Token_Count);
      when others =>
         null;
      end case;
      New_Node := new Action_Node'(Symbol, new Parse_Action_Node'(Action, null), null);
      if State.Action_List = null then
         State.Action_List := New_Node;
      else
         Node := State.Action_List;
         loop
            exit when Node.Next = null;
            Node := Node.Next;
         end loop;
         Node.Next := New_Node;
      end if;
   end Add_Action;

   procedure Add_Action
     (State           : in out Parse_State;
      Symbols         : in     Token_ID_Array;
      Production      : in     Production_ID;
      RHS_Token_Count : in     Ada.Containers.Count_Type;
      Semantic_Action : in     WisiToken.Syntax_Trees.Semantic_Action;
      Semantic_Check  : in     WisiToken.Semantic_Checks.Semantic_Check)
   is begin
      --  We assume Duplicate_Reduce is True for this state; no
      --  conflicts, all the same action.
      for Symbol of Symbols loop
         Add_Action
           (State, Symbol, Reduce, Production, RHS_Token_Count,
            Semantic_Action, Semantic_Check);
      end loop;
      Add_Error (State);
   end Add_Action;

   procedure Add_Conflict
     (State             : in out LR.Parse_State;
      Symbol            : in     Token_ID;
      Reduce_Production : in     Production_ID;
      RHS_Token_Count   : in     Ada.Containers.Count_Type;
      Semantic_Action   : in     WisiToken.Syntax_Trees.Semantic_Action;
      Semantic_Check    : in     Semantic_Checks.Semantic_Check)
   is
      Conflict : constant Parse_Action_Rec :=
        (Reduce, Reduce_Production, Semantic_Action, Semantic_Check, RHS_Token_Count);
      Node : Parse_Action_Node_Ptr := Find (Symbol, State.Action_List).Action;
   begin
      loop
         exit when Node.Next = null;
         Node := Node.Next;
      end loop;
      Node.Next := new Parse_Action_Node'(Conflict, null);
   end Add_Conflict;

   procedure Add_Error (State  : in out LR.Parse_State)
   is
      Action : constant Parse_Action_Rec := (Verb => Error);
      Node   : Action_Node_Ptr           := State.Action_List;
   begin
      if Node = null then
         raise SAL.Programmer_Error with "adding an error action to a parse table state before other actions.";
      end if;
      loop
         exit when Node.Next = null;
         Node := Node.Next;
      end loop;
      Node.Next := new Action_Node'(Invalid_Token_ID, new Parse_Action_Node'(Action, null), null);
   end Add_Error;

   procedure Add_Goto
     (State      : in out LR.Parse_State;
      Symbol     : in     Token_ID;
      To_State   : in     State_Index)
   is
      List     : Goto_Node_Ptr renames State.Goto_List;
      New_Item : constant Goto_Node_Ptr := new Goto_Node'(Symbol, To_State, null);
      I        : Goto_Node_Ptr := List;
   begin
      if I = null then
         List := New_Item;
      else
         if List.Symbol > Symbol then
            New_Item.Next := List;
            List          := New_Item;
         else
            if List.Next = null then
               List.Next := New_Item;
            else
               I := List;
               loop
                  exit when I.Next = null or List.Symbol > Symbol;
                  I := I.Next;
               end loop;
               New_Item.Next := I.Next;
               I.Next        := New_Item;
            end if;
         end if;
      end if;
   end Add_Goto;

   function Goto_For
     (Table : in Parse_Table;
      State : in State_Index;
      ID    : in Token_ID)
     return Unknown_State_Index
   is
      Goto_Node : constant Goto_Node_Ptr := Goto_For (Table, State, ID);
   begin
      if Goto_Node = null then
         --  We can only get here during error recovery.
         return Unknown_State;
      else
         return Goto_Node.State;
      end if;
   end Goto_For;

   function Goto_For
     (Table : in Parse_Table;
      State : in State_Index;
      ID    : in Token_ID)
     return Goto_Node_Ptr
   is
      Goto_Node : Goto_Node_Ptr := Table.States (State).Goto_List;
   begin
      while Goto_Node /= null and then Goto_Node.Symbol /= ID loop
         Goto_Node := Goto_Node.Next;
      end loop;

      return Goto_Node;
   end Goto_For;

   function Action_For
     (Table : in Parse_Table;
      State : in State_Index;
      ID    : in Token_ID)
     return Parse_Action_Node_Ptr
   is
      Action_Node : Action_Node_Ptr := Table.States (State).Action_List;
   begin
      if Action_Node = null then
         raise SAL.Programmer_Error with "no actions for state" & Unknown_State_Index'Image (State);
      end if;

      while Action_Node.Next /= null and Action_Node.Symbol /= ID loop
         Action_Node := Action_Node.Next;
      end loop;

      return Action_Node.Action;
   end Action_For;

   function Expecting (Table : in Parse_Table; State : in State_Index) return Token_ID_Set
   is
      Result : Token_ID_Set    := (Table.First_Terminal .. Table.Last_Terminal => False);
      Action : Action_Node_Ptr := Table.States (State).Action_List;
   begin
      loop
         --  Last action is error; don't include it.
         exit when Action.Next = null;

         Result (Action.Symbol) := True;
         Action := Action.Next;
      end loop;
      return Result;
   end Expecting;

   procedure Free_Table (Table : in out Parse_Table_Ptr)
   is

      procedure Free is new Ada.Unchecked_Deallocation (Parse_Table, Parse_Table_Ptr);
      Action            : Action_Node_Ptr;
      Temp_Action       : Action_Node_Ptr;
      Parse_Action      : Parse_Action_Node_Ptr;
      Temp_Parse_Action : Parse_Action_Node_Ptr;
      Got               : Goto_Node_Ptr;
      Temp_Got          : Goto_Node_Ptr;
   begin
      if Table = null then
         return;
      end if;

      for State of Table.States loop
         Action := State.Action_List;
         loop
            exit when Action = null;
            Parse_Action := Action.Action;
            loop
               exit when Parse_Action = null;
               Temp_Parse_Action := Parse_Action;
               Parse_Action := Parse_Action.Next;
               Free (Temp_Parse_Action);
            end loop;

            Temp_Action := Action;
            Action := Action.Next;
            Free (Temp_Action);
         end loop;

         Got := State.Goto_List;
         loop
            exit when Got = null;
            Temp_Got := Got;
            Got := Got.Next;
            Free (Temp_Got);
         end loop;
      end loop;

      Free (Table);
   end Free_Table;

   function Get_Text_Rep
     (File_Name      : in String;
      McKenzie_Param : in McKenzie_Param_Type;
      Actions        : in Semantic_Action_Array_Arrays.Vector)
     return Parse_Table_Ptr
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
            raise SAL.Programmer_Error with Error_Message
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
            raise SAL.Programmer_Error with Error_Message
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
         raise SAL.Programmer_Error with Error_Message
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
      function Next_Boolean is new Gen_Next_Value (Boolean, "Boolean");
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

         Table.McKenzie_Param := McKenzie_Param;

         for State of Table.States loop
            declare
               Node_I       : Action_Node_Ptr := new Action_Node;
               Actions_Done : Boolean         := False;
            begin
               State.Action_List := Node_I;
               loop
                  declare
                     Node_J      : Parse_Action_Node_Ptr := new Parse_Action_Node;
                     Action_Done : Boolean := False;
                     Verb        : Parse_Action_Verbs;
                  begin
                     Node_I.Action := Node_J;
                     loop
                        Verb := Next_Parse_Action_Verbs;
                        Node_J.Item :=
                          (case Verb is
                           when Shift     => (Verb => Shift, others => <>),
                           when Reduce    => (Verb => Reduce, others => <>),
                           when Accept_It => (Verb => Accept_It, others => <>),
                           when Error     => (Verb => Error));

                        case Verb is
                        when Shift =>
                           Node_J.Item.State := Next_State_Index;

                        when Reduce | Accept_It =>
                           Node_J.Item.Production.LHS := Next_Token_ID;
                           Node_J.Item.Production.RHS := Next_Integer;
                           if Next_Boolean then
                              Node_J.Item.Action := Actions
                                (Node_J.Item.Production.LHS)(Node_J.Item.Production.RHS).Action;
                           else
                              Node_J.Item.Action := null;
                           end if;
                           if Next_Boolean then
                              Node_J.Item.Check := Actions
                                (Node_J.Item.Production.LHS)(Node_J.Item.Production.RHS).Check;
                           else
                              Node_J.Item.Check := null;
                           end if;
                           Node_J.Item.Token_Count := Next_Count_Type;

                        when Error =>
                           Actions_Done := True;
                        end case;

                        if Check_Semicolon then
                           Action_Done := True;

                           if not Actions_Done then
                              Node_I.Symbol := Next_Token_ID;
                           end if;
                        end if;

                        exit when Action_Done;

                        Node_J.Next := new Parse_Action_Node;
                        Node_J      := Node_J.Next;
                     end loop;

                     Check_New_Line;
                  end;

                  exit when Actions_Done;
                  Node_I.Next := new Action_Node;
                  Node_I      := Node_I.Next;
               end loop;
            end;

            if Check_Semicolon then
               --  No Gotos
               null;
            else
               declare
                  Node_I : Goto_Node_Ptr := new Goto_Node;
               begin
                  State.Goto_List  := Node_I;
                  loop
                     Node_I.Symbol := Next_Token_ID;
                     Node_I.State  := Next_State_Index;
                     exit when Check_Semicolon;
                     Node_I.Next   := new Goto_Node;
                     Node_I        := Node_I.Next;
                  end loop;
               end;
            end if;
            Check_New_Line;

            declare
               First : constant Integer := Next_Integer;
               Last  : constant Integer := Next_Integer;
            begin
               if Last = -1 then
                  --  State.Kernel not set for state 0
                  null;
               else
                  State.Kernel.Set_First (Count_Type (First));
                  State.Kernel.Set_Last (Count_Type (Last));

                  for I in State.Kernel.First_Index .. State.Kernel.Last_Index loop
                     State.Kernel (I).LHS := Next_Token_ID;
                     State.Kernel (I).Before_Dot := Next_Token_ID;
                     State.Kernel (I).Length_After_Dot := Count_Type (Next_Integer);
                  end loop;
               end if;
            end;
            Check_New_Line;

            if Check_Semicolon then
               --  No minimal action
               null;
            else
               State.Minimal_Complete_Actions.Set_First (Count_Type (Next_Integer));
               State.Minimal_Complete_Actions.Set_Last (Count_Type (Next_Integer));
               for I in State.Minimal_Complete_Actions.First_Index .. State.Minimal_Complete_Actions.Last_Index loop
                  declare
                     Verb         : constant Minimal_Verbs := Next_Parse_Action_Verbs;
                     ID           : Token_ID;
                     Action_State : State_Index;
                     Count        : Ada.Containers.Count_Type;
                  begin
                     case Verb is
                     when Shift =>
                        ID           := Next_Token_ID;
                        Action_State := Next_State_Index;
                        State.Minimal_Complete_Actions.Replace_Element (I, (Shift, ID, Action_State));
                     when Reduce =>
                        ID    := Next_Token_ID;
                        Count := Next_Count_Type;
                        State.Minimal_Complete_Actions.Replace_Element (I, (Reduce, ID, Count));
                     end case;
                  end;
               end loop;
               Check_Semicolon;
            end if;
            Check_New_Line;

            exit when Check_EOI;
         end loop;
         return Table;
      end;
   exception
   when Name_Error =>
      raise User_Error with "parser table text file '" & File_Name & "' not found.";

   when SAL.Programmer_Error =>
      raise;

   when E : others =>
      raise SAL.Programmer_Error with Error_Message
        (File_Name, 1, Ada.Text_IO.Count (Buffer_Last),
         Ada.Exceptions.Exception_Name (E) & ": " & Ada.Exceptions.Exception_Message (E));
   end Get_Text_Rep;

   function Compare (Left, Right : in Insert_Delete_Op) return SAL.Compare_Result
   is
      Left_Token_Index : constant WisiToken.Token_Index :=
        (case Insert_Delete_Op_Label'(Left.Op) is
         when Insert => Left.Ins_Token_Index,
         when Delete => Left.Del_Token_Index);
      Right_Token_Index : constant WisiToken.Token_Index :=
        (case Insert_Delete_Op_Label'(Right.Op) is
         when Insert => Right.Ins_Token_Index,
         when Delete => Right.Del_Token_Index);
   begin
      if Left_Token_Index < Right_Token_Index then
         return SAL.Less;
      elsif Left_Token_Index = Right_Token_Index then
         return SAL.Equal;
      else
         return SAL.Greater;
      end if;
   end Compare;

   function Equal (Left : in Config_Op; Right : in Insert_Op) return Boolean
   is begin
      return Left.Op = Insert and then
        Left.Ins_ID = Right.Ins_ID and then
        Left.Ins_Token_Index = Right.Ins_Token_Index;
   end Equal;

   function None_Since_FF (Ops : in Config_Op_Arrays.Vector; Op : in Config_Op_Label) return Boolean
   is begin
      for O of reverse Ops loop
         exit when O.Op = Fast_Forward;
         if O.Op = Op then
            return False;
         end if;
      end loop;
      return True;
   end None_Since_FF;

   function Only_Since_FF (Ops : in Config_Op_Arrays.Vector; Op : in Config_Op_Label) return Boolean
   is
      use all type Ada.Containers.Count_Type;
   begin
      if Ops.Length = 0 or else Ops (Ops.Last_Index).Op /= Op then
         return False;
      else
         for O of reverse Ops loop
            exit when O.Op = Fast_Forward;
            if O.Op /= Op then
               return False;
            end if;
         end loop;
         return True;
      end if;
   end Only_Since_FF;

   function Valid_Tree_Indices (Stack : in Recover_Stacks.Stack; Depth : in SAL.Base_Peek_Type) return Boolean
   is
      use all type WisiToken.Syntax_Trees.Node_Index;
   begin
      for I in 1 .. Depth loop
         if Stack (I).Tree_Index = Syntax_Trees.Invalid_Node_Index then
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
