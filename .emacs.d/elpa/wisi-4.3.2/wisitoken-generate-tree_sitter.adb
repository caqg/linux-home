--  Abstract :
--
--  See spec.
--
--  References:
--
--  [1] tree-sitter grammar: https://tree-sitter.github.io/tree-sitter/creating-parsers#the-grammar-dsl
--
--  Copyright (C) 2020 - 2023 Stephen Leake All Rights Reserved.
--
--  This library is free software;  you can redistribute it and/or modify it
--  under terms of the  GNU General Public License  as published by the Free
--  Software  Foundation;  either version 3,  or (at your  option) any later
--  version. This library is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN-
--  TABILITY or FITNESS FOR A PARTICULAR PURPOSE.

pragma License (GPL);

with Ada.Strings.Fixed;
with Ada.Text_IO; use Ada.Text_IO;
with SAL.Gen_Unbounded_Definite_Vectors;
with WisiToken.BNF.Output_Ada_Common;
with WisiToken.Syntax_Trees.LR_Utils;
with WisiToken_Grammar_Editing;
with Wisitoken_Grammar_Actions; use Wisitoken_Grammar_Actions;
package body WisiToken.Generate.Tree_Sitter is
   use WisiToken.Syntax_Trees;

   function Is_Possibly_Empty_ID (Tree : in Syntax_Trees.Tree; Node : in Valid_Node_Access) return Boolean
   is (To_Token_Enum (Tree.ID (Node)) in rhs_ID | rhs_item_list_ID | rhs_item_ID);

   procedure Eliminate_Empty_Productions
     (Data     : in out WisiToken_Grammar_Runtime.User_Data_Type;
      Tree     : in out WisiToken.Syntax_Trees.Tree;
      No_Empty : in     Boolean)
   is
      use all type Ada.Containers.Count_Type;

      Ignore_Lines : Boolean := False;

      type Empty_Nonterm is record
         Name : Ada.Strings.Unbounded.Unbounded_String;
         --  The nonterm name, for trace messages.

         Empty_Node : WisiToken.Syntax_Trees.Node_Access := WisiToken.Syntax_Trees.Invalid_Node_Access;
         --  The first element of an RHS that can be empty.
      end record
      with Dynamic_Predicate =>
        Empty_Node = Invalid_Node_Access or else
        Is_Possibly_Empty_ID (Tree, Empty_Node);

      package Empty_Nonterm_Lists is new SAL.Gen_Unbounded_Definite_Vectors
        (Positive_Index_Type, Empty_Nonterm, Default_Element => (others => <>));

      Empty_Nonterms  : Empty_Nonterm_Lists.Vector;
      Nodes_To_Delete : Valid_Node_Access_Lists.List;
      Nodes_To_Check  : Valid_Node_Access_Lists.List;
      --  If we edit a node to now contain an optional item, it might become
      --  possibly empty.

      function Get_Text (Node : in Valid_Node_Access) return String
      is begin
         return WisiToken_Grammar_Runtime.Get_Text (Data, Tree, Node);
      end Get_Text;

      function Can_Be_Empty (Node : in Valid_Node_Access) return Node_Access
      --  Return a descendant node of Node that can be empty, Invalid_Node_Access if none.
      with Pre => To_Token_Enum (Tree.ID (Node)) in
                  rhs_list_ID | rhs_item_list_ID | rhs_alternative_list_ID | rhs_element_ID
      is
         use Syntax_Trees.LR_Utils;
      begin
         case To_Token_Enum (Tree.ID (Node)) is
         when rhs_list_ID =>
            declare
               use all type SAL.Base_Peek_Type;
               RHS_List : constant Constant_List := Creators.Create_List (Tree, Node, +rhs_list_ID, +rhs_ID);
            begin
               for RHS of RHS_List loop
                  if Tree.Child_Count (RHS) = 0 then
                     return RHS;
                  end if;
                  declare
                     Empty_Node : constant Node_Access := Can_Be_Empty
                       (Tree.Child (RHS, (if Tree.ID (Tree.Child (RHS, 1)) = +rhs_item_list_ID then 1 else 2)));
                  begin
                     if Empty_Node /= Invalid_Node_Access then
                        return Empty_Node;
                     end if;
                  end;
               end loop;
               return Invalid_Node_Access;
            end;

         when rhs_item_list_ID =>
            declare
               Item_List : constant Constant_List := Creators.Create_List
                 (Tree, Node, +rhs_item_list_ID, +rhs_element_ID);
            begin
               for Element of Item_List loop
                  declare
                     Empty_Node : constant Node_Access := Can_Be_Empty (Element);
                  begin
                     if Empty_Node = Invalid_Node_Access then
                        --  This item can't be empty, so the list can't be empty.
                        return Invalid_Node_Access;
                     end if;
                  end;
               end loop;
               --  All items can be empty
               return Node;
            end;

         when rhs_element_ID =>
            declare
               Item : constant Valid_Node_Access := Tree.Child (Tree.Find_Descendant (Node, +rhs_item_ID), 1);
            begin
               case To_Token_Enum (Tree.ID (Item)) is
               when IDENTIFIER_ID | STRING_LITERAL_SINGLE_ID =>
                  return Invalid_Node_Access;

               when attribute_ID =>
                  --  If the only elements in an rhs_item_list are attributes, the list
                  --  is empty for LR generation purposes.
                  return Item;

               when rhs_optional_item_ID =>
                  return Item;

               when rhs_multiple_item_ID =>
                  declare
                     use all type SAL.Base_Peek_Type;
                     First_Child : constant Valid_Node_Access := Tree.Child (Item, 1);
                  begin
                     case To_Token_Enum (Tree.ID (First_Child)) is
                     when LEFT_BRACE_ID =>
                        return
                          (if Tree.Child_Count (Item) = 3
                           then Item
                           else Invalid_Node_Access);

                     when LEFT_PAREN_ID =>
                        return
                          (if To_Token_Enum (Tree.ID (Tree.Child (Item, 4))) = STAR_ID
                           then Item
                           else Invalid_Node_Access);

                     when IDENTIFIER_ID =>
                        return
                          (if To_Token_Enum (Tree.ID (Tree.Child (Item, 2))) = STAR_ID
                           then Item
                           else Invalid_Node_Access);

                     when others =>
                        raise SAL.Programmer_Error;
                     end case;
                  end;

               when rhs_group_item_ID =>
                  return Can_Be_Empty (Tree.Child (Item, 2));

               when others =>
                  raise SAL.Programmer_Error;
               end case;
            end;

         when rhs_alternative_list_ID =>
            declare
               RHS_Alt_List_1 : constant Constant_List := Creators.Create_List
                 (Tree, Tree.Child (Node, Tree.Child_Count (Node)), +rhs_alternative_list_1_ID, +rhs_item_list_ID);
            begin
               for Item_List of RHS_Alt_List_1 loop
                  declare
                     Empty_Node : constant Node_Access := Can_Be_Empty (Item_List);
                  begin
                     if Empty_Node /= Invalid_Node_Access then
                        return Empty_Node;
                     end if;
                  end;
               end loop;
               return Invalid_Node_Access;
            end;

         when others =>
            raise SAL.Programmer_Error;
         end case;
      end Can_Be_Empty;

      procedure Find_Empty_Nodes (Node : in Valid_Node_Access)
      is begin
         if Ignore_Lines then
            case To_Token_Enum (Tree.ID (Node)) is
            when declaration_ID =>
               --  Contained in a compilation_unit that is already marked for deletion
               case To_Token_Enum (Tree.ID (Tree.Child (Node, 2))) is
               when ELSIF_ID =>
                  --  | PERCENT ELSIF IDENTIFIER EQUAL IDENTIFIER
                  --  | PERCENT ELSIF IDENTIFIER IN IDENTIFIER_BAR_LIST
                  declare
                     use WisiToken.BNF;
                  begin
                     if "lexer" = Get_Text (Tree.Child (Node, 3)) then
                        Ignore_Lines := not WisiToken_Grammar_Runtime.Get_Lexer_Set
                          (Data, Tree, Tree.Child (Node, 5)) (Tree_Sitter_Lexer);

                     elsif "parser" = Get_Text (Tree.Child (Node, 3)) then
                        Ignore_Lines := not WisiToken_Grammar_Runtime.Get_Generate_Algorithm_Set
                          (Data, Tree, Tree.Child (Node, 5)) (WisiToken.BNF.Tree_Sitter);

                     else
                        raise SAL.Programmer_Error;
                     end if;

                     if Trace_Generate_EBNF > Outline then
                        Ada.Text_IO.Put_Line
                          ("ignore lines " & Ignore_Lines'Image & " line" &
                             Tree.Line_Region (Tree.Child (Node, 1), Trailing_Non_Grammar => True).First'Image);
                     end if;
                  end;

               when END_ID =>
                  --  | PERCENT END IF
                  Ignore_Lines := False;
                  if Trace_Generate_EBNF > Outline then
                     Ada.Text_IO.Put_Line
                       ("ignore lines false line" &
                          Tree.Line_Region (Tree.Child (Node, 1), Trailing_Non_Grammar => True).First'Image);
                  end if;

               when others =>
                  null;
               end case;

            when compilation_unit_ID =>
               Nodes_To_Delete.Append (Node);
               Find_Empty_Nodes (Tree.Child (Node, 1));

            when compilation_unit_list_ID =>
               declare
                  Children : constant Node_Access_Array := Tree.Children (Node);
               begin
                  case To_Token_Enum (Tree.ID (Children (1))) is
                  when compilation_unit_list_ID =>
                     Find_Empty_Nodes (Children (1));
                     Find_Empty_Nodes (Children (2));

                  when compilation_unit_ID =>
                     Find_Empty_Nodes (Children (1));

                  when others =>
                     raise SAL.Programmer_Error;
                  end case;
               end;

            when rhs_list_ID =>
               Generate.Put_Error
                 (Tree.Error_Message (Node, "%if in rhs_list not supported with tree_sitter."));

            when others =>
               null;
            end case;
            return;
         end if;

         case To_Token_Enum (Tree.ID (Node)) is
         --  SOI, EOI first, then Enum_Token_ID alphabetical order

         when Wisi_SOI_ID | Wisi_EOI_ID =>
            null;

         when compilation_unit_ID =>
            Find_Empty_Nodes (Tree.Child (Node, 1));

         when compilation_unit_list_ID =>
            declare
               Children : constant Node_Access_Array := Tree.Children (Node);
            begin
               case To_Token_Enum (Tree.ID (Children (1))) is
               when compilation_unit_list_ID =>
                  Find_Empty_Nodes (Children (1));
                  Find_Empty_Nodes (Children (2));
               when compilation_unit_ID =>
                  Find_Empty_Nodes (Children (1));
               when others =>
                  raise SAL.Programmer_Error;
               end case;
            end;

         when declaration_ID =>
            case To_Token_Enum (Tree.ID (Tree.Child (Node, 2))) is
            when IF_ID | ELSIF_ID =>
               --  | PERCENT (IF | ELSIF) IDENTIFIER (EQUAL IDENTIFIER | IN IDENTIFIER_BAR_list)
               Nodes_To_Delete.Append (Node);
               declare
                  use WisiToken.BNF;
               begin
                  if "lexer" = Get_Text (Tree.Child (Node, 3)) then
                     Ignore_Lines := not WisiToken_Grammar_Runtime.Get_Lexer_Set
                       (Data, Tree, Tree.Child (Node, 5)) (Tree_Sitter_Lexer);

                  elsif "parser" = Get_Text (Tree.Child (Node, 3)) then
                     Ignore_Lines := not WisiToken_Grammar_Runtime.Get_Generate_Algorithm_Set
                       (Data, Tree, Tree.Child (Node, 5)) (WisiToken.BNF.Tree_Sitter);

                  else
                     raise SAL.Programmer_Error;
                  end if;

                  if Ignore_Lines and Trace_Generate_EBNF > Outline then
                     Ada.Text_IO.Put_Line
                       ("ignore lines TRUE line" &
                          Tree.Line_Region (Tree.Child (Node, 1), Trailing_Non_Grammar => True).First'Image);
                  end if;

               end;

            when END_ID =>
               --  %end if
               Nodes_To_Delete.Append (Node);

            when others =>
               null;
            end case;

         when nonterminal_ID =>
            declare
               Empty_Node : constant Node_Access := Can_Be_Empty
                 (Tree.Child (Node, (if Tree.ID (Tree.Child (Node, 3)) = +rhs_list_ID then 3 else 4)));
            begin
               if Empty_Node /= Invalid_Node_Access then
                  Empty_Nonterms.Append
                    ((+WisiToken_Grammar_Runtime.Get_Text (Data, Tree, Tree.Child (Node, 1)),
                      Empty_Node));
               end if;
            end;

         when wisitoken_accept_ID =>
            Find_Empty_Nodes (Tree.Child (Node, 2));

         when others =>
            raise SAL.Not_Implemented with Tree.Image (Node, Node_Numbers => True);
         end case;
      end Find_Empty_Nodes;

      procedure Delete_Node (Node : in Valid_Node_Access)
      with Pre => To_Token_Enum (Tree.ID (Node)) in compilation_unit_ID | declaration_ID | rhs_list_ID | rhs_ID
      is
         use Syntax_Trees.LR_Utils;
      begin
         if Trace_Generate_EBNF > Detail then
            Ada.Text_IO.Put_Line
              ("delete " & Tree.Image (Node, Node_Numbers => True));
         end if;

         case To_Token_Enum (Tree.ID (Node)) is
         when compilation_unit_ID | declaration_ID =>
            declare
               Element : constant Valid_Node_Access :=
                 (if Tree.ID (Node) = +compilation_unit_ID then Node else Tree.Parent (Node));

               Container : List   := Creators.Create_From_Element
                 (Tree, Element, +compilation_unit_list_ID, +compilation_unit_ID, Separator_ID => Invalid_Token_ID);
               Cur       : Cursor := Container.To_Cursor (Element);
            begin
               Container.Delete (Cur);
            end;

         when rhs_list_ID =>
            --  %if in an rhs_list is not a canonical list element, so we can't
            --  use LR_Utils.Delete. Which is why it's not supported.
            raise SAL.Not_Implemented;

         when rhs_ID =>
            declare
               Container : List   := Creators.Create_From_Element
                 (Tree, Node, +rhs_list_ID, +rhs_ID, Separator_ID => Invalid_Token_ID);
               Cur       : Cursor := Container.To_Cursor (Node);
            begin
               Container.Delete (Cur);
            end;

         when others =>
            raise SAL.Programmer_Error;
         end case;
      end Delete_Node;

      procedure Make_Non_Empty (Empty_Node : in Valid_Node_Access)
      with Pre => Is_Possibly_Empty_ID (Tree, Empty_Node)
      --  Empty_Node is the first item in an RHS that can be empty; change
      --  the RHS to be non-empty.
      is
         use WisiToken.Syntax_Trees.LR_Utils;
         use all type SAL.Base_Peek_Type;

         procedure Make_Non_Empty_RHS_Item (Item : in Valid_Node_Access)
         with Pre =>
           Tree.ID (Item) = +rhs_item_ID and
           To_Token_Enum (Tree.ID (Tree.Child (Item, 1))) in rhs_optional_item_ID | rhs_multiple_item_ID
         --  Edit Item so it cannot be empty. Higher level code promotes the
         --  empty case to a higher level nonterm.
         is
            Item_Var : Valid_Node_Access := Item;
         begin
            case To_Token_Enum (Tree.ID (Tree.Child (Item, 1))) is
            when rhs_optional_item_ID =>
               declare
                  Optional_Item :  Valid_Node_Access := Tree.Child (Item, 1);
               begin
                  case To_Token_Enum (Tree.ID (Tree.Child (Optional_Item, 1))) is
                  when LEFT_BRACKET_ID =>

                     Tree.Set_Children
                       (Node     => Optional_Item,
                        New_ID   => (+rhs_group_item_ID, 0),
                        Children =>
                          (1     => Tree.Add_Terminal (+LEFT_PAREN_ID),
                           2     => Tree.Child (Optional_Item, 2),
                           3     => Tree.Add_Terminal (+RIGHT_PAREN_ID)));

                     Tree.Set_Children
                       (Node     => Item_Var,
                        New_ID   => (+rhs_item_ID, 4),
                        Children =>
                          (1     => Optional_Item));

                  when LEFT_PAREN_ID =>

                     Tree.Set_Children
                       (Node     => Optional_Item,
                        New_ID   => (+rhs_group_item_ID, 0),
                        Children => Tree.Children (Optional_Item) (1 .. 3));

                     Tree.Set_Children
                       (Node     => Item_Var,
                        New_ID   => (+rhs_item_ID, 4),
                        Children =>
                          (1     => Optional_Item));

                  when IDENTIFIER_ID =>

                     Tree.Set_Children
                       (Node     => Item_Var,
                        New_ID   => (+rhs_item_ID, 0),
                        Children => (1 => Tree.Child (Optional_Item, 1)));

                  when STRING_LITERAL_SINGLE_ID =>

                     Tree.Set_Children
                       (Node     => Item_Var,
                        New_ID   => (+rhs_item_ID, 1),
                        Children => (1 => Tree.Child (Optional_Item, 1)));

                  when others =>
                     raise SAL.Programmer_Error;
                  end case;
               end;

            when rhs_multiple_item_ID =>
               declare
                  Multiple_Item  : Valid_Node_Access          := Tree.Child (Item, 1);
                  First_Child    : constant Valid_Node_Access := Tree.Child (Multiple_Item, 1);
                  First_Child_ID : constant Token_Enum_ID     := To_Token_Enum (Tree.ID (First_Child));
               begin
                  pragma Assert
                    (case First_Child_ID is
                     when LEFT_BRACE_ID => Tree.Child_Count (Multiple_Item) = 3,
                     when LEFT_PAREN_ID => Tree.ID (Tree.Child (Multiple_Item, 4)) = +STAR_ID,
                     when IDENTIFIER_ID => Tree.ID (Tree.Child (Multiple_Item, 2)) = +STAR_ID,
                     when others => raise SAL.Programmer_Error);

                  Tree.Set_Children
                    (Node => Multiple_Item,
                     New_ID =>
                       (LHS => +rhs_multiple_item_ID,
                        RHS =>
                          (case Tree.RHS_Index (Multiple_Item) is
                           when 0 => 1,
                           when 3 => 2,
                           when 5 => 4,
                           when others => raise SAL.Programmer_Error)),
                     Children =>
                       (case Tree.RHS_Index (Multiple_Item) is
                        when 0 | 3 =>
                          (1 => Tree.Child (Multiple_Item, 1),
                           2 => Tree.Child (Multiple_Item, 2),
                           3 => Tree.Child (Multiple_Item, 3),
                           4 => (case Tree.RHS_Index (Multiple_Item) is
                                 when 0 => Tree.Add_Terminal (+MINUS_ID),
                                 when 3 => Tree.Add_Terminal (+PLUS_ID),
                                 when others => raise SAL.Programmer_Error)),
                        when 5 => (1 => Tree.Child (Multiple_Item, 1)),
                        when others => raise SAL.Programmer_Error));
               end;

            when others =>
               raise SAL.Programmer_Error;
            end case;
         end Make_Non_Empty_RHS_Item;

      begin
         case To_Token_Enum (Tree.ID (Empty_Node)) is
         when rhs_ID =>
            --  An empty RHS.
            Delete_Node (Empty_Node);

         when rhs_item_list_ID =>
            declare
               Item_List  : constant Constant_List     := Creators.Create_List
                 (Tree, Empty_Node, +rhs_item_list_ID, +rhs_element_ID);
               First_Item : constant Valid_Node_Access := Element (Item_List.First);
               Item       : constant Valid_Node_Access := Tree.Find_Descendant (First_Item, +rhs_item_ID);
            begin
               Make_Non_Empty_RHS_Item (Item);
            end;

         when rhs_item_ID =>
            Make_Non_Empty_RHS_Item (Empty_Node);

         when others =>
            raise SAL.Programmer_Error;
         end case;
      end Make_Non_Empty;

      procedure Make_Optional (Name : in String)
      --  Convert all occurences of Name in RHS to optional, because it used
      --  to be possibly empty. Add edited nonterms to Node_To_Check; they
      --  may now be possibly empty.
      is
         procedure Find_Nodes (Node : in Valid_Node_Access)
         --  Search subtree at Node for Name
         is
            use all type SAL.Base_Peek_Type;
            Node_Var : Node_Access := Node;
         begin
            case To_Token_Enum (Tree.ID (Node)) is
            --  common code first, then Enum_Token_ID alphabetical order

            when wisitoken_accept_ID =>
               Find_Nodes (Tree.Child (Node, 2));

            when rhs_alternative_list_ID =>
               Find_Nodes (Tree.Child (Node, Tree.Child_Count (Node)));

            when compilation_unit_ID =>
               Find_Nodes (Tree.Child (Node, 1));

            when compilation_unit_list_ID | rhs_alternative_list_1_ID | rhs_item_list_ID | rhs_list_ID =>
               declare
                  Children : constant Node_Access_Array := Tree.Children (Node);
               begin
                  Find_Nodes (Children (1));
                  if Tree.Child_Count (Node) > 1 then
                     Find_Nodes
                       (Children
                          (case To_Token_Enum (Tree.ID (Node)) is
                           when compilation_unit_list_ID  | rhs_item_list_ID => 2,
                           when rhs_alternative_list_1_ID | rhs_list_ID      => 3,
                           when others => raise SAL.Programmer_Error));
                  end if;
               end;

            when declaration_ID =>
               return;

            when nonterminal_ID =>
               if Name = Get_Text (Tree.Child (Node, 1)) then
                  return;
               end if;

               Find_Nodes (Tree.Child (Node, 3));

            when rhs_element_ID =>
               Find_Nodes (Tree.Child (Node, (if Tree.RHS_Index (Node) = 0 then 1 else 3)));

            when rhs_group_item_ID =>
               Find_Nodes (Tree.Child (Node, 2));

            when rhs_item_ID =>
               case To_Token_Enum (Tree.ID (Tree.Child (Node, 1))) is
               when IDENTIFIER_ID =>
                  if Name = Get_Text (Tree.Child (Node, 1)) then
                     --  IMPROVEME: could check if already optional (ie parent is single
                     --  rhs_item_list contained in single rhs_alternative_list contained
                     --  in rhs_optional_item), which means the source grammar should be
                     --  changed.

                     Nodes_To_Check.Append (Node);
                     declare
                        Child : constant Valid_Node_Access := WisiToken_Grammar_Editing.Add_RHS_Optional_Item
                          (Tree,
                           RHS_Index => 2, -- IDENTIFIER QUESTION
                           Content   => Tree.Child (Node, 1));
                     begin
                        Tree.Set_Children (Node_Var, (+rhs_item_ID, 2), (1 => Child));
                     end;
                  end if;

               when STRING_LITERAL_SINGLE_ID =>
                  null;

               when attribute_ID | rhs_optional_item_ID | rhs_multiple_item_ID | rhs_group_item_ID =>
                  Find_Nodes (Tree.Child (Node, 1));

               when others =>
                  raise SAL.Programmer_Error;
               end case;

            when rhs_multiple_item_ID =>
               case To_Token_Enum (Tree.ID (Tree.Child (Node, 1))) is
               when LEFT_BRACE_ID | LEFT_PAREN_ID =>
                  Find_Nodes (Tree.Child (Node, 2));

               when IDENTIFIER_ID =>
                  if Name = Get_Text (Tree.Child (Node, 1)) and
                    To_Token_Enum (Tree.ID (Tree.Child (Node, 2))) = STAR_ID
                  then
                     Generate.Put_Error
                       (Tree.Error_Message (Node, "'" & Name & "' is both optional and possibly empty."));
                  end if;

               when others =>
                  raise SAL.Programmer_Error;
               end case;

            when rhs_optional_item_ID =>
               case Tree.RHS_Index (Node) is
               when 0 | 1 =>
                  Find_Nodes (Tree.Child (Node, 2));

               when 2 | 3 =>
                  --  already optional
                  null;
               when others =>
                  raise SAL.Programmer_Error;
               end case;

            when rhs_ID =>
               if Tree.Child_Count (Node) = 0 then
                  return;
               else
                  Find_Nodes (Tree.Child (Node, 1));
               end if;

            when others =>
               raise SAL.Programmer_Error with "Make_Optional.Find_Nodes name " & Name & " in node " & Tree.Image
                 (Node, Node_Numbers => True);
            end case;
         end Find_Nodes;

      begin
         Find_Nodes (Tree.Root);
      end Make_Optional;

   begin
      WisiToken_Grammar_Editing.EBNF_Allowed := True;

      if Trace_Generate_EBNF > Outline then
         Ada.Text_IO.New_Line;
         Ada.Text_IO.Put_Line ("tree_sitter eliminate empty productions start");
         if Trace_Generate_EBNF > Detail then
            Tree.Print_Tree (Tree.Root);
            Ada.Text_IO.New_Line;
         end if;
      end if;

      Find_Empty_Nodes (Tree.Root);
      --  Also finds %if etc, adds them to Nodes_To_Delete.

      if No_Empty and Empty_Nonterms.Length > 0 then
         declare
            use Ada.Strings.Unbounded;
            Empty_Image : Unbounded_String;
         begin
            for Nonterm of Empty_Nonterms loop
               Append (Empty_Image, Nonterm.Name);
               Append (Empty_Image, " ");
            end loop;
            raise Grammar_Error with "Tree_Sitter forbids possibly empty nonterms: " & (-Empty_Image);
         end;
      end if;

      if Trace_Generate_EBNF > Outline then
         Ada.Text_IO.Put_Line ("nodes to delete:" & Nodes_To_Delete.Length'Image);
      end if;

      for Node of Nodes_To_Delete loop
         Delete_Node (Node);
      end loop;
      Nodes_To_Delete.Clear;

      Data.Error_Reported.Clear;

      if Debug_Mode then
         Tree.Validate_Tree
           (Data'Unchecked_Access, Data.Error_Reported,
            Root              => Tree.Root,
            Validate_Node     => WisiToken_Grammar_Editing.Validate_Node'Access,
            Node_Index_Order  => True,
            Line_Number_Order => False);
      end if;

      if Trace_Generate_EBNF > Outline then
         Ada.Text_IO.Put_Line ("empty nonterms:");
         for Nonterm of Empty_Nonterms loop
            Ada.Text_IO.Put (-Nonterm.Name & ", ");
         end loop;
         Ada.Text_IO.New_Line (2);
      end if;

      for Nonterm of Empty_Nonterms loop
         --  IMPROVEME: tree-sitter allows the start nonterm of the grammar to be empty,
         --  but no other nonterms may be empty. But we don't find Start_Node until we are in Print_Tree_Sitter.
         Make_Non_Empty (Nonterm.Empty_Node);
      end loop;

      if Trace_Generate_EBNF > Outline then
         Ada.Text_IO.Put_Line ("after Make_Non_Empty");
         Ada.Text_IO.New_Line;
      end if;

      if Debug_Mode then
         Tree.Validate_Tree
           (Data'Unchecked_Access, Data.Error_Reported,
            Root             => Tree.Root,
            Validate_Node    => WisiToken_Grammar_Editing.Validate_Node'Access,
            Node_Index_Order => False); --  Implies Line_Number_Order = False
      end if;

      for Nonterm of Empty_Nonterms loop
         Make_Optional (-Nonterm.Name);
      end loop;

      if Trace_Generate_EBNF > Outline then
         Ada.Text_IO.Put_Line ("after Make_Optional");
         Ada.Text_IO.New_Line;
      end if;

      if Debug_Mode then
         Tree.Validate_Tree
           (Data'Unchecked_Access, Data.Error_Reported,
            Root             => Tree.Root,
            Validate_Node    => WisiToken_Grammar_Editing.Validate_Node'Access,
            Node_Index_Order => False);
      end if;

      declare
         use Valid_Node_Access_Lists;
         Cur  : Cursor := Nodes_To_Check.First;
         Temp : Cursor;
      begin
         loop
            exit when not Has_Element (Cur);
            declare
               RHS_List_Node : constant Valid_Node_Access := Tree.Find_Ancestor (Element (Cur), +rhs_list_ID);
               Nonterm_Node  : constant Valid_Node_Access := Tree.Parent (RHS_List_Node);

               Empty_Node : constant Node_Access := Can_Be_Empty (RHS_List_Node);
            begin
               if Empty_Node /= Invalid_Node_Access then
                  declare
                     Nonterm_Name : constant String := Get_Text (Tree.Child (Nonterm_Node, 1));
                  begin
                     if Trace_Generate_EBNF > Outline then
                        Ada.Text_IO.Put_Line ("newly empty nonterm " & Nonterm_Name);
                     end if;

                     Make_Non_Empty (Empty_Node);
                     Make_Optional (Nonterm_Name);
                  end;
               end if;
            end;
            Temp := Cur;
            Cur  := Next (Cur);
            Nodes_To_Check.Delete (Temp);
         end loop;
      end;

      if Trace_Generate_EBNF > Outline then
         Ada.Text_IO.Put_Line ("after Nodes_To_Check");
         Ada.Text_IO.New_Line;
      end if;

      if Debug_Mode then
         Tree.Validate_Tree
           (Data'Unchecked_Access, Data.Error_Reported,
            Root             => Tree.Root,
            Validate_Node    => WisiToken_Grammar_Editing.Validate_Node'Access,
            Node_Index_Order => False);
      end if;

      if Trace_Generate_EBNF > Detail then
         Ada.Text_IO.Put_Line ("tree_sitter eliminate empty productions end");
         Tree.Print_Tree (Tree.Root);
         Ada.Text_IO.New_Line;
      end if;
   end Eliminate_Empty_Productions;

   procedure Print_Tree_Sitter
     (Data             : in     WisiToken_Grammar_Runtime.User_Data_Type;
      Tree             : in out Syntax_Trees.Tree;
      Lexer            : in     WisiToken.Lexer.Handle;
      Output_File_Name : in     String;
      Language_Name    : in     String)
   is
      use all type Ada.Containers.Count_Type;

      --  We process the EBNF tree, not the grammar description in Data, to
      --  take advantage of the higher-level tree_sitter grammar
      --  descriptions like 'optional' and 'repeat'.

      --  'hidden rules'
      --  (https://tree-sitter.github.io/tree-sitter/creating-parsers#hiding-rules)
      --  are different from 'inline'
      --  (https://tree-sitter.github.io/tree-sitter/creating-parsers#the-grammar-dsl);
      --  hidden rules are in the parse table, inline are not. The parse
      --  action for hidden rules does not create a syntax tree node. We
      --  don't support them in the wisi parser generator, because that
      --  would mean Undo_Reduce cannot be implemented, which is required
      --  for our error recover algorithm. (IMPROVEME: maybe undo_reduce
      --  is just more complicated?).
      --
      --  For now, we don't use them in the generated tree-sitter grammar,
      --  so client code doesn't care whether it's a wisi or tree-sitter
      --  parser.

      Extras    : WisiToken.BNF.String_Lists.List;
      Conflicts : WisiToken.BNF.String_Lists.List;

      Start_Node : Node_Access := Invalid_Node_Access;

      --  Local specs

      procedure Put_RHS_Item_List (Node : in Valid_Node_Access; First : in Boolean)
      with Pre => Tree.ID (Node) = +rhs_item_list_ID;

      --  Local bodies

      procedure Put_Commented (Text : in WisiToken.BNF.String_Lists.List)
      is begin
         for Line of Text loop
            Put_Line ("// " & Line);
         end loop;
      end Put_Commented;

      function Get_Text (Tree_Index : in Valid_Node_Access) return String
      is
         function Strip_Delimiters (Tree_Index : in Valid_Node_Access) return String
         is
            Region : Buffer_Region renames Tree.Byte_Region (Tree_Index, Trailing_Non_Grammar => False);
         begin
            if -Tree.ID (Tree_Index) in RAW_CODE_ID | REGEXP_ID | ACTION_ID then
               --  Strip delimiters. We don't strip leading/trailing spaces to preserve indent.
               return Lexer.Buffer_Text ((Region.First + 2, Region.Last - 2));

               --  We don't strip string delimiters; tree-setter can use the same ones.
            else
               return Lexer.Buffer_Text (Region);
            end if;
         end Strip_Delimiters;

      begin
         case Tree.Label (Tree_Index) is
         when Source_Terminal =>
            return Strip_Delimiters (Tree_Index);

         when Virtual_Terminal =>
            --  Terminal keyword inserted during tree edit. We could check for
            --  Identifier, but that will be caught later.
            return Image (Tree.ID (Tree_Index), Wisitoken_Grammar_Actions.Descriptor);

         when Virtual_Identifier =>
            raise SAL.Programmer_Error;

         when Nonterm =>
            declare
               use all type Ada.Strings.Unbounded.Unbounded_String;
               Result       : Ada.Strings.Unbounded.Unbounded_String;
               Tree_Indices : constant Valid_Node_Access_Array := Tree.Get_Terminals (Tree_Index);
               Need_Space   : Boolean                                      := False;
            begin
               for Tree_Index of Tree_Indices loop
                  Result := Result & (if Need_Space then " " else "") &
                    Get_Text (Tree_Index);
                  Need_Space := True;
               end loop;
               return -Result;
            end;
         end case;
      end Get_Text;

      procedure Not_Translated (Label : in String; Node : in Valid_Node_Access)
      is begin
         New_Line;
         Put ("// " & Label & ": not translated: " & Node_Access'Image (Node) & ":" &
                Tree.Image (Node, Children => True));

         Put_Line
           (Current_Error,
            Tree.Error_Message
              (Node,
               Label & ": not translated: " &
                 Tree.Image
                   (Node,
                    RHS_Index    => True,
                    Children     => True,
                    Node_Numbers => True)));
      end Not_Translated;

      procedure Put_Attr_List (Attr_List : in Valid_Node_Access)
      is
         Prec  : constant WisiToken.Base_Precedence_ID := WisiToken_Grammar_Runtime.Get_Precedence
           (Data, Tree, Attr_List);
         Assoc : constant WisiToken.Associativity      := WisiToken_Grammar_Runtime.Get_Associativity
           (Data, Tree, Attr_List);
      begin
         case Assoc is
         when Left =>
            Put ("prec.left(");

         when Right =>
            Put ("prec.right(");

         when None =>
            pragma Assert (Prec /= No_Precedence);
            Put ("prec(");
         end case;
         if Prec /= No_Precedence then
            Put ("'" & (-Data.Precedence_Inverse_Map (Prec)) & "', ");
         end if;
      end Put_Attr_List;

      procedure Put_RHS_Alternative_List_1 (Node : in Valid_Node_Access; First : in Boolean)
      with Pre => Tree.ID (Node) = +rhs_alternative_list_1_ID
      is begin
         case To_Token_Enum (Tree.ID (Tree.Child (Node, 1))) is
         when rhs_item_list_ID =>
            --  Only one alternative, don't need "choice()".
            Put_RHS_Item_List (Tree.Child (Node, 1), First => True);

         when rhs_alternative_list_1_ID =>
            if First then
               Put ("choice(");
            end if;

            Put_RHS_Alternative_List_1 (Tree.Child (Node, 1), First => False);
            Put (", ");
            Put_RHS_Item_List (Tree.Child (Node, 3), First => True);

            if First then
               Put (")");
            end if;

         when others =>
            Not_Translated ("Put_RHS_Alternative_List_1", Node);
         end case;
      end Put_RHS_Alternative_List_1;

      procedure Put_RHS_Alternative_List (Node : in Valid_Node_Access)
      with Pre => Tree.ID (Node) = +rhs_alternative_list_ID
      is
         RHS_Alt_List_1 : Valid_Node_Access := Tree.Child (Node, 1);
      begin
         if Tree.ID (Tree.Child (Node, 1)) = +attribute_list_ID then
            Put_Attr_List (Tree.Child (Node, 1));
            RHS_Alt_List_1 := Tree.Child (Node, 2);
         end if;

         Put_RHS_Alternative_List_1 (RHS_Alt_List_1, First => True);
      end Put_RHS_Alternative_List;

      procedure Put_RHS_Optional_Item (Node : in Valid_Node_Access)
      with Pre => Tree.ID (Node) = +rhs_optional_item_ID
      is begin
         Put ("optional(");

         case To_Token_Enum (Tree.ID (Tree.Child (Node, 1))) is
         when LEFT_BRACKET_ID | LEFT_PAREN_ID =>
            Put_RHS_Alternative_List (Tree.Child (Node, 2));
         when IDENTIFIER_ID =>
            Put ("$." & Get_Text (Tree.Child (Node, 1)));
         when STRING_LITERAL_SINGLE_ID =>
            Put (Get_Text (Tree.Child (Node, 1)));
         when others =>
            raise SAL.Programmer_Error;
         end case;

         Put (")");
      end Put_RHS_Optional_Item;

      procedure Put_RHS_Multiple_Item (Node : in Valid_Node_Access)
      with Pre => Tree.ID (Node) = +rhs_multiple_item_ID
      is begin
         case Tree.RHS_Index (Node) is
         when 0 | 3 =>
            Put ("repeat(");
            Put_RHS_Alternative_List (Tree.Child (Node, 2));
            Put (")");

         when 1 | 2 =>
            Put ("repeat1(");
            Put_RHS_Alternative_List (Tree.Child (Node, 2));
            Put (")");

         when 4 =>
            Put ("repeat1(");
            Put ("$." & Get_Text (Tree.Child (Node, 1)));
            Put (")");

         when 5 =>
            Put ("repeat(");
            Put ("$." & Get_Text (Tree.Child (Node, 1)));
            Put (")");

         when others =>
            Not_Translated ("Put_RHS_Multiple_Item", Node);
         end case;
      end Put_RHS_Multiple_Item;

      procedure Put_RHS_Group_Item (Node : in Valid_Node_Access)
      with Pre => Tree.ID (Node) = +rhs_group_item_ID
      is begin
         Put_RHS_Alternative_List (Tree.Child (Node, 2));
      end Put_RHS_Group_Item;

      procedure Put_RHS_Item (Node : in Valid_Node_Access)
      with Pre => Tree.ID (Node) = +rhs_item_ID
      is
         function Keyword_Name (Decl : in Valid_Node_Access) return String
         with Pre => KEYWORD_ID = To_Token_Enum (Tree.ID (Tree.Child (Decl, 2)))
         is begin
            return Get_Text (Tree.Child (Decl, 3));
         end Keyword_Name;

      begin
         case To_Token_Enum (Tree.ID (Tree.Child (Node, 1))) is
         when IDENTIFIER_ID =>
            Put ("$." & Get_Text (Node));

         when STRING_LITERAL_SINGLE_ID =>
            --  Case insensitive
            declare
               Text : constant String := Get_Text (Node);

               --  Token may be declared with "...", but referenced with '...'.
               Decl : constant Node_Access := WisiToken_Grammar_Editing.Find_Declaration_By_Value
                 (Data, Tree, Text (Text'First + 1 .. Text'Last - 1), Strip_Quotes => True);
            begin
               if Decl = Invalid_Node_Access then
                  Put ("caseInsensitive(" & Text & ")");
               else
                  case To_Token_Enum (Tree.ID (Tree.Child (Decl, 2))) is
                  when Wisitoken_Grammar_Actions.TOKEN_ID =>
                     --  Assume it's punctuation or similar where case doesn't matter.
                     Put (Text);

                  when KEYWORD_ID =>
                     Put ("$." & Keyword_Name (Decl));

                  when others =>
                     raise SAL.Programmer_Error;
                  end case;
               end if;
            end;

         when attribute_ID =>
            null;

         when rhs_optional_item_ID =>
            Put_RHS_Optional_Item (Tree.Child (Node, 1));

         when rhs_multiple_item_ID =>
            Put_RHS_Multiple_Item (Tree.Child (Node, 1));

         when rhs_group_item_ID =>
            Put_RHS_Group_Item (Tree.Child (Node, 1));

         when others =>
            raise SAL.Programmer_Error with "node: " & Trimmed_Image (Node);
         end case;
      end Put_RHS_Item;

      procedure Put_RHS_Element (Node : in Valid_Node_Access)
      with Pre => Tree.ID (Node) = +rhs_element_ID
      is begin
         case Tree.RHS_Index (Node) is
         when 0 =>
            Put_RHS_Item (Tree.Child (Node, 1));

         when 1 =>
            Put ("field('" & Get_Text (Tree.Child (Node, 1)) & "', ");
            Put_RHS_Item (Tree.Child (Node, 3));
            Put (")");

         when others =>
            raise SAL.Programmer_Error;
         end case;
      end Put_RHS_Element;

      procedure Put_RHS_Item_List (Node : in Valid_Node_Access; First : in Boolean)
      is
         Children : constant Node_Access_Array := Tree.Children (Node);
      begin
         if Children'Length = 1 then
            Put_RHS_Element (Children (1));
         else
            if First then
               Put ("seq(");
            end if;
            Put_RHS_Item_List (Children (1), First => False);
            Put (", ");
            Put_RHS_Element (Children (2));

            if First then
               Put (")");
            end if;
         end if;
      end Put_RHS_Item_List;

      procedure Put_RHS (Node : in Valid_Node_Access)
      with Pre => Tree.ID (Node) = +rhs_ID
      is begin
         case Tree.RHS_Index (Node) is
         when 0 =>
            Generate.Put_Error
              (Tree.Error_Message
                 ((declare
                      RHS_List : constant Valid_Node_Access := Tree.Parent (Node);
                   begin
                      (case Tree.RHS_Index (RHS_List) is
                       when 0 => RHS_List,
                       when others => Tree.Child (RHS_List, 2))),
                  "empty RHS forbidden by tree-sitter"));

         when 1 .. 6 =>
            if Tree.ID (Tree.Child (Node, 1)) = +attribute_list_ID then
               Put_Attr_List (Tree.Child (Node, 1));
               Put_RHS_Item_List (Tree.Child (Node, 2), First => True);
               Put (')');
            else
               Put_RHS_Item_List (Tree.Child (Node, 1), First => True);
            end if;

            --  tree-sitter does not have actions in the grammar. FIXME: output
            --  actions map to separate file for Emacs wisi with tree-sitter
            --  parser.

         when others =>
            raise SAL.Programmer_Error;
         end case;
      end Put_RHS;

      procedure Put_RHS_List (Node : in Valid_Node_Access; First : in Boolean)
      with Pre => Tree.ID (Node) = +rhs_list_ID
      is
         Children : constant Node_Access_Array := Tree.Children (Node);
      begin
         case Tree.RHS_Index (Node) is
         when 0 =>
            Put_RHS (Children (1));

         when 1 =>
            if First then
               Put ("choice(");
               Indent := @ + 2;
            end if;

            Put_RHS_List (Children (1), First => False);
            Put (", ");
            Put_RHS (Children (3));

            if First then
               Put (")");
               Indent := @ - 2;
            end if;

         when 2 .. 6 =>
            --  Could have been eliminated by Eliminate_Empty_Productions, but that's hard.
            Generate.Put_Error
              (Tree.Error_Message (Node, "%if in rhs_list not supported with tree_sitter."));

         when others =>
               raise SAL.Programmer_Error;
         end case;
      end Put_RHS_List;

      function String_Regexp (Value : in Valid_Node_Access) return String
      with Pre => To_Token_Enum (Tree.ID (Value)) in STRING_LITERAL_DOUBLE_ID | STRING_LITERAL_SINGLE_ID | REGEXP_ID
      --  Return a javascript expression for Value
      is
         use Ada.Strings, Ada.Strings.Fixed;
      begin
         return
         (case To_Token_Enum (Tree.ID (Value)) is
            when STRING_LITERAL_DOUBLE_ID | STRING_LITERAL_SINGLE_ID => Get_Text (Value),

            when REGEXP_ID =>
               --  Value must be '/.../' or 'new RegExp("...")' as needed; not checked here.
               Trim (Get_Text (Value), Both),

            when others => raise SAL.Programmer_Error);
      end String_Regexp;

      procedure Process_Node (Node : in Valid_Node_Access)
      is begin
         if Node = Start_Node then
            return;
         end if;

         case To_Token_Enum (Tree.ID (Node)) is
         --  SOI, EOI first, then Enum_Token_ID alphabetical order

         when Wisi_SOI_ID | Wisi_EOI_ID =>
            null;

         when compilation_unit_ID =>
            Process_Node (Tree.Child (Node, 1));

         when compilation_unit_list_ID =>
            raise SAL.Programmer_Error;

         when declaration_ID =>
            case To_Token_Enum (Tree.ID (Tree.Child (Node, 2))) is
            when Wisitoken_Grammar_Actions.TOKEN_ID | NON_GRAMMAR_ID =>
               declare
                  Kind  : constant String      := Get_Text (Tree.Child (Node, 4));
                  Name  : constant String      := Get_Text (Tree.Child (Node, 6));
                  Regexp_String : constant Node_Access := Tree.Child (Node, 7);
                  Value : constant Node_Access :=
                    (if Regexp_String = Invalid_Node_Access
                     then Invalid_Node_Access
                     else Tree.Child (Regexp_String, 1));
                  --  We are ignoring any repair image; tree_sitter grammar does not
                  --  support that.
               begin

                  if Kind = "comment-new-line" then
                     if not (To_Token_Enum (Tree.ID (Value)) in
                               STRING_LITERAL_DOUBLE_ID | STRING_LITERAL_SINGLE_ID)
                     then
                        Generate.Put_Error
                          (Tree.Error_Message
                             (Node, "string literal required for comment-new-line; found " &
                                Image (Tree.ID (Value), Tree.Lexer.Descriptor.all)));
                     else

                        --  WORKAROUND: tree-sitter 0.16.6 treats rule "token(seq('--',
                        --  /.*/))" correctly for an Ada comment, but not extra "/--.*/". See
                        --  github tree-sitter issue 651 - closed without resolving this
                        --  question, but it does provide a workaround.
                        Indent_Line (Name & ": $ => token(seq(" & Get_Text (Value) & ", /.*/)),");
                        New_Line;
                        Extras.Append ("$." & Name);
                     end if;

                  elsif Kind = "comment-one-line" then
                     --  FIXME: We need to provide an external scanner for this.
                     raise SAL.Not_Implemented with "comment-one-line not implemented in tree_sitter";

                  elsif Kind = "delimited-text" then
                     --  FIXME: We need to provide an external scanner for this.
                     raise SAL.Not_Implemented with "comment-one-line not implemented in tree_sitter";

                  elsif Value = Invalid_Node_Access then
                     --  new-line with no regexp; tree-sitter defaults to DOS and Unix newline.
                     null;

                  else
                     --  If the source grammar uses string literals in the nonterminal
                     --  RHSs, we don't need to define this token. However, some code using
                     --  this parser may rely on the token names, so we define them to
                     --  ensure they are the same for wisi and tree-sitter parsers.
                     Indent_Line (Name & ": $ => " & String_Regexp (Value) & ",");
                     New_Line;
                  end if;
               end;

            when KEYWORD_ID =>
               declare
                  Name  : constant String      := Get_Text (Tree.Child (Node, 3));
                  Value : constant Node_Access := Tree.Child (Tree.Child (Node, 4), 1);
               begin
                  --  Value is a string or regular expression.
                  case To_Token_Enum (Tree.ID (Value)) is
                  when STRING_LITERAL_DOUBLE_ID | STRING_LITERAL_SINGLE_ID =>

                     if To_Token_Enum (Tree.ID (Value)) = STRING_LITERAL_SINGLE_ID or
                       Data.Language_Params.Case_Insensitive
                     then
                        Indent_Line (Name & ": $ => reservedInsensitive(" & Get_Text (Value) & "),");

                     else
                        --  Case sensitive
                        --
                        --  Wisitoken follows the re2c convention; single quoted strings are
                        --  case insensitive. See comment at definition of
                        --  'reservedInsenstive' below for 'reserved' use.
                        Indent_Line (Name & ": $ => reserved(" & Get_Text (Value) & "),");
                     end if;

                  when REGEXP_ID =>
                     Indent_Line (Name & ": $ => " & String_Regexp (Value) & ",");

                  when others =>
                     raise SAL.Programmer_Error with "node: " & Trimmed_Image (Node)'Image;
                  end case;
                  New_Line;
               end;

            when CODE_ID =>
               declare
                  Loc_List : constant Syntax_Trees.Valid_Node_Access_Array :=
                    WisiToken_Grammar_Runtime.Get_Code_Location_List (Tree, Node);
               begin
                  if Get_Text (Loc_List (Loc_List'First)) = "copyright_license" then
                     --  handled in Print_Tree_Sitter top level
                     null;
                  else
                     Generate.Put_Error (Tree.Error_Message (Node, "%code with tree-sitter not supported."));
                  end if;
               end;

            when CONFLICT_ID =>
               --  .wy LR format:
               --  %conflict action LHS (| action LHS)* 'on token' on
               --            I      I+1
               --
               --  .wy Tree_Sitter format:
               --  %conflict LHS (LHS)*
               --
               --  .js format:
               --  [$.LHS, $.LHS, ...]

               declare
                  use Ada.Strings.Unbounded;

                  Tree_Indices : constant Valid_Node_Access_Array := Tree.Get_Terminals (Tree.Child (Node, 3));
                  Result       : Unbounded_String                := +"[";
               begin
                  if Tree_Indices'Length < 3 or else Tree.ID (Tree_Indices (3)) /= +BAR_ID then
                     --  Tree_Sitter format
                     for LHS of Tree_Indices loop
                        Result := @ & "$." & Get_Text (LHS) & ", ";
                     end loop;

                  else
                     --  LR format
                     declare
                        use all type SAL.Base_Peek_Type;
                        I : SAL.Peek_Type := Tree_Indices'First;
                     begin
                        loop
                           Result := @ & "$." & Get_Text (Tree_Indices (I + 1)) & ", ";

                           I := I + 3;
                           exit when I > Tree_Indices'Last;
                        end loop;
                     end;
                  end if;
                  Conflicts.Append (-Result & ']');
               end;

            when CONFLICT_RESOLUTION_ID =>
               null;

            when IDENTIFIER_ID =>
               declare
                  Kind : constant String := Get_Text (Tree.Child (Node, 2));
               begin
                  if Kind = "case_insensitive" then
                     --  The meta phase grammar file parse sets
                     --  Data.Language_Params.Case_Insensitive.
                     null;

                  elsif Kind = "elisp_action" then
                     --  Used in generating Action code
                     null;

                  elsif Kind = "elisp_face" then
                     --  Used in generating Action code
                     null;

                  elsif Kind = "elisp_indent" then
                     --  Used in generating Action code
                     null;

                  elsif Kind = "generate" then
                     --  Handled in meta phase grammar parser.
                     null;

                  elsif Kind = "lexer_regexp" then
                     --  Handled in Print_Tree_Sitter top level
                     null;

                  elsif Kind = "meta_syntax" then
                     --  Handled in meta phase grammar parser.
                     null;

                  elsif Kind = "precedence" then
                     --  Handled in Print_Tree_Sitter top level
                     null;

                  elsif Kind = "start" then
                     --  Handled in Print_Tree_Sitter top level.
                     null;

                  else
                     Generate.Put_Error
                       (Tree.Error_Message (Node, "declaration not supported with tree_sitter."));
                  end if;
               end;

            when IF_ID | ELSIF_ID | END_ID =>
               --  Should have been eliminated by Eliminate_Empty_Productions
               raise SAL.Programmer_Error with "Print_Tree_Sitter declaration %if " &
                 Tree.Image (Node, Node_Numbers => True);

            when others =>
               raise SAL.Programmer_Error;
            end case;

         when nonterminal_ID =>
            declare
               Children : constant Node_Access_Array := Tree.Children (Node);
            begin
               Indent_Start (Get_Text (Children (1)) & ": $ => ");

               if Tree.ID (Tree.Child (Node, 2)) = +attribute_list_ID then
                  Put_Attr_List (Tree.Child (Node, 2));
                  Put_RHS_List (Children (4), First => True);
                  Put (')');
               else
                  Put_RHS_List (Children (3), First => True);
               end if;

               Put_Line (",");
               New_Line;
            end;

         when wisitoken_accept_ID =>
            --  Child 1 is SOI, 2 compilation_unit_list
            Process_Node (Tree.Child (Node, 2));

         when others =>
            raise SAL.Not_Implemented with Image (Tree.ID (Node), Wisitoken_Grammar_Actions.Descriptor);
         end case;
      end Process_Node;

      use Syntax_Trees.LR_Utils;
      Compilation_Unit_List : constant Constant_List := Creators.Create_List
        (Tree, Tree.Find_Descendant (Tree.Root, +compilation_unit_list_ID),
         +compilation_unit_list_ID, +compilation_unit_ID);

   begin
      if Trace_Generate_EBNF > Outline then
         Put_Line ("translate to tree_sitter");
      end if;

      declare
         File : File_Type;
      begin
         Create (File, Out_File, Output_File_Name);
         Set_Output (File);

         Indent := 1;
         Indent_Line ("// generated from " & Tree.Lexer.File_Name & " -*- buffer-read-only:t js-indent-level:3 -*-");
         New_Line;

         for Unit of Compilation_Unit_List loop
            declare
               Node : constant Valid_Node_Access := Tree.Child (Unit, 1);
            begin
               if To_Token_Enum (Tree.ID (Node)) = declaration_ID and then
                 To_Token_Enum (Tree.ID (Tree.Child (Node, 2))) = CODE_ID
               then
                  declare
                     Loc_List : constant Syntax_Trees.Valid_Node_Access_Array :=
                       WisiToken_Grammar_Runtime.Get_Code_Location_List (Tree, Node);
                  begin
                     if Get_Text (Loc_List (Loc_List'First)) = "copyright_license" then
                        Put_Commented (WisiToken.BNF.Split_Lines (Get_Text (Tree.Child (Node, 4))));
                     else
                        Generate.Put_Error (Tree.Error_Message (Node, "%code with tree-sitter not supported."));
                     end if;
                  end;
                  exit;
               end if;
            end;
         end loop;

         --  First some useful functions

         --  'word' is reserved in tree-sitter;
         --  https://tree-sitter.github.io/tree-sitter/creating-parsers#keywords.
         --
         --  However, since we support case insensitive keywords, we can't rely
         --  on that mechanism to ignore keywords that are not bounded by word
         --  separators. So we use precedence. The only way we can tell if a
         --  STRING_LITERAL_SINGLE token in an RHS needs this is to find the
         --  declaration for it, and check if it is %keyword. So all reserved
         --  keywords must be declared.

         Indent_Line ("const reserved = regex => token(prec(2, new RegExp(regex)));");
         Indent_Line
           ("const caseInsensitive = word => word.split('')" &
              " .map(letter => `[${letter}${letter.toUpperCase()}]`) .join('');");
         Indent_Line ("const reservedInsensitive = word => alias(reserved(caseInsensitive(word)), word) ;");
         New_Line;

         --  Now any lexer_regexp
         for Unit of Compilation_Unit_List loop
            declare
               Node : constant Valid_Node_Access := Tree.Child (Unit, 1);
            begin
               if To_Token_Enum (Tree.ID (Node)) = declaration_ID and then
                 To_Token_Enum (Tree.ID (Tree.Child (Node, 2))) = IDENTIFIER_ID and then
                 Get_Text (Tree.Child (Node, 2)) = "lexer_regexp"
               then
                  declare
                     Terminals : constant Valid_Node_Access_Array := Tree.Get_Terminals (Tree.Child (Node, 3));

                     Name  : constant String      := Get_Text (Terminals (1));
                     Value : constant Node_Access := Terminals (2);
                  begin
                     Put_Line ("const " & Name & " = " & String_Regexp (Value) & ";");
                  end;
               end if;
            end;
         end loop;

         Indent_Line ("module.exports = grammar({");
         Indent := @ + 3;

         Indent_Line ("name: '" & Language_Name & "',");
         New_Line;

         if not Data.Precedence_Lists.Is_Empty then
            Indent_Line ("precedences: () => [");
            Indent := @ + 2;
            for List of Data.Precedence_Lists loop
               Indent_Line ("[");
               Indent := @ + 2;
               for ID of List loop
                  Indent_Line ("'" & (-Data.Precedence_Inverse_Map (ID)) & "',");
               end loop;
               Indent := @ - 2;
               Indent_Line ("],");
            end loop;
            Indent := @ - 2;

            Indent_Line ("],");
            New_Line;
         end if;

         Indent_Line ("rules: {");
         Indent := @ + 3;

         --  Start symbol must be the first rule; that's how tree-sitter knows
         --  it's the start symbol. accept rule with wisi-eoi is implicit in
         --  tree-sitter (as in .wy).
         if -Data.Language_Params.Start_Token = "" then
            Generate.Put_Error (Generate.Error_Message (Tree.Lexer.File_Name, 1, "%start not specified"));
         else
            declare
               Temp : constant Node_Access := WisiToken_Grammar_Editing.Find_Declaration
                 (Data, Tree, -Data.Language_Params.Start_Token);
            begin
               Process_Node (Temp);
               Start_Node := Temp;
            end;
         end if;

         --  A grammar typically consists of a large number of
         --  compilation_units, each one fairly short. Process_Node is
         --  recursive; if we use that to process the compilation_Units, it can
         --  overflow the stack (it did for ada_full.wy). So we handle the
         --  compilation_Units as a list here, and use recursion for the
         --  declarations and nonterms.
         for Unit of Compilation_Unit_List loop
            Process_Node (Unit);
         end loop;

         Put ("  }");
         Indent := @ - 3;

         if Conflicts.Length > 0 then
            Put_Line (",");
            Put_Line ("  conflicts: $ => [");
            Indent := @ + 3;
            for Item of Conflicts loop
               Indent_Line (Item & ",");
            end loop;
            Put ("  ]");
            Indent := @ - 3;
         end if;

         if Extras.Length > 0 then
            --  Since we have an explicit 'extras', we need to specify space and newline.
            Extras.Append ("/\s|\\\r?\n/");
            Put_Line (",");
            Put_Line ("  extras: $ => [");
            Indent := @ + 3;
            for Item of Extras loop
               Indent_Line (Item & ",");
            end loop;
            Put_Line ("  ],");
            Indent := @ - 3;
         end if;
         Put ("}");
         Indent := @ - 3;
         pragma Assert (Indent = 1);

         Indent_Line (");");
         Set_Output (Standard_Output);

         Close (File);
      end;
   end Print_Tree_Sitter;

   procedure Create_Test_Main (Output_File_Name_Root : in String)
   is
      use WisiToken.BNF;

      Ada_Name_Root : constant String := Output_Ada_Common.File_Name_To_Ada (Output_File_Name_Root);
      Unit_Name     : constant String := Ada_Name_Root & "_Tree_Sitter_Run";

      File_Name : constant String := To_Lower (Unit_Name) & ".adb";

      File : File_Type;

   begin
      Create (File, Out_File, File_Name);
      Set_Output (File);

      Put_File_Header (Ada_Comment);
      --  no Copyright_License; just a test file
      New_Line;

      Put_Line ("with Interfaces.C.Extensions;");
      Put_Line ("with Gen_Tree_Sitter_Parser_Run;");
      Put_Line ("procedure " & Unit_Name);
      Put_Line ("is");
      Put_Line ("   function Tree_Sitter_" & Ada_Name_Root & " return Interfaces.C.Extensions.void_ptr");
      Put_Line ("   with Import     => True,");
      Put_Line ("     External_Name => ""tree_sitter_" & Ada_Name_Root & """,");
      Put_Line ("     Convention    => C;");
      Put_Line ("   procedure Parse_Run is new Gen_Tree_Sitter_Parser_Run");
      Put_Line ("     (Tree_Sitter_Language => Tree_Sitter_" & Ada_Name_Root & ");");
      Put_Line ("begin");
      Put_Line ("   Parse_Run;");
      Put_Line ("end " & Unit_Name & ";");
      Close (File);
      Set_Output (Standard_Output);
   end Create_Test_Main;

end WisiToken.Generate.Tree_Sitter;
--  Local Variables:
--  ada-case-strict: nil
--  End:
