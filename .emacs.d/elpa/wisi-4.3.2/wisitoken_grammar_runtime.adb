--  Abstract :
--
--  See spec.
--
--  Copyright (C) 2018 - 2023 Free Software Foundation, Inc.
--
--  This library is free software;  you can redistribute it and/or modify it
--  under terms of the  GNU General Public License  as published by the Free
--  Software  Foundation;  either version 3,  or (at your  option) any later
--  version. This library is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN-
--  TABILITY or FITNESS FOR A PARTICULAR PURPOSE.

--  As a special exception under Section 7 of GPL version 3, you are granted
--  additional permissions described in the GCC Runtime Library Exception,
--  version 3.1, as published by the Free Software Foundation.

pragma License (Modified_GPL);

with Ada.Exceptions;
with Ada.Strings.Unbounded;
with WisiToken.Generate;   use WisiToken.Generate;
with WisiToken.Syntax_Trees.LR_Utils;
package body WisiToken_Grammar_Runtime is

   use WisiToken;
   use Wisitoken_Grammar_Actions;

   ----------
   --  Body subprograms, misc order

   procedure Set_EBNF
     (Tree : in Syntax_Trees.Tree;
      Node : in Syntax_Trees.Valid_Node_Access)
   is
      use all type WisiToken.Syntax_Trees.Augmented_Class_Access;

      Tree_Aug : constant WisiToken.Syntax_Trees.Augmented_Class_Access := Tree.Augmented (Node);
      Aug      : constant Augmented_Access :=
        (if Tree_Aug = null
         then new Augmented
         else Augmented_Access (Tree_Aug));
   begin
      if Tree_Aug = null then
         Tree.Set_Augmented (Node, WisiToken.Syntax_Trees.Augmented_Class_Access (Aug));
      end if;
      Aug.EBNF := True;
   end Set_EBNF;

   function Get_Text
     (Data         : in User_Data_Type;
      Tree         : in Syntax_Trees.Tree;
      Tree_Index   : in WisiToken.Syntax_Trees.Valid_Node_Access;
      Strip_Quotes : in Boolean := False)
     return String
   is begin
      return Get_Text
        (Data.Tokens.Virtual_Identifiers,
         Tree, Tree_Index, Strip_Quotes);
   end Get_Text;

   function Get_Item_Text
     (Data         : in User_Data_Type;
      Tree         : in Syntax_Trees.Tree;
      Node         : in Syntax_Trees.Valid_Node_Access;
      Strip_Quotes : in Boolean := False)
     return String
   is begin
      return Get_Text (Data, Tree, Tree.Find_Descendant (Node, +rhs_item_ID), Strip_Quotes);
   end Get_Item_Text;

   function Get_Child_Text
     (Data         : in User_Data_Type;
      Tree         : in Syntax_Trees.Tree;
      Parent       : in Syntax_Trees.Valid_Node_Access;
      Child        : in SAL.Peek_Type;
      Strip_Quotes : in Boolean := False)
     return String
   is
      Tree_Indices : constant Syntax_Trees.Valid_Node_Access_Array := Tree.Get_Terminals (Parent);
   begin
      return Get_Text (Data, Tree, Tree_Indices (Child), Strip_Quotes);
   end Get_Child_Text;

   procedure Start_If_1
     (Data    : in out User_Data_Type;
      Tree    : in out Syntax_Trees.Tree;
      A_Index : in     Syntax_Trees.Valid_Node_Access;
      B_Index : in     Syntax_Trees.Valid_Node_Access)
   is
      use WisiToken.BNF;
   begin
      if "lexer" = Get_Text (Data, Tree, A_Index) then
         declare
            Right : constant Lexer_Set := Get_Lexer_Set (Data, Tree, B_Index);
         begin
            Data.If_Lexer_Present := True;
            Data.Ignore_Lines     := not Right (Data.User_Lexer);
         end;

      elsif "parser" = Get_Text (Data, Tree, A_Index) then
         Data.If_Parser_Present := True;
         declare
            Right : constant Generate_Algorithm_Set := Get_Generate_Algorithm_Set (Data, Tree, B_Index);
         begin
            Data.Ignore_Lines := not Right (Data.User_Parser);
         end;

      else
         Put_Error (Tree.Error_Message ((A_Index), "invalid '%if'; must be one of {lexer | parser}"));
      end if;
   end Start_If_1;

   function Get_RHS
     (Data   : in out User_Data_Type;
      Tree   : in out Syntax_Trees.Tree;
      Labels : in out WisiToken.BNF.String_Arrays.Vector;
      Token  : in     Syntax_Trees.Valid_Node_Access)
     return WisiToken.BNF.RHS_Type
   with Pre => Tree.ID (Token) = +rhs_ID
   is
      use all type WisiToken.Syntax_Trees.Augmented_Class_Access;
      use all type SAL.Base_Peek_Type;
      Children : constant Syntax_Trees.Node_Access_Array := Tree.Children (Token);
   begin
      return RHS : WisiToken.BNF.RHS_Type do
         RHS.Source_Line := Tree.Line_Region (Token, Trailing_Non_Grammar => True).First;

         if Tree.Augmented (Token) = null then
            RHS.Orig_EBNF_RHS := True;
         else
            declare
               Aug : constant Augmented_Access := Augmented_Access (Tree.Augmented (Token));
            begin
               RHS.Orig_EBNF_RHS     := Aug.Orig_EBNF_RHS;
               RHS.EBNF_RHS_Index    := Aug.EBNF_RHS_Index;
               RHS.Auto_Token_Labels := Aug.Auto_Token_Labels;
            end;
         end if;

         if Children'Length > 0 then
            declare
               use WisiToken.Syntax_Trees;

               Attr_List     : Node_Access := Invalid_Node_Access;
               RHS_Item_List : Node_Access;
               Action_1      : Node_Access := Invalid_Node_Access;
               Action_2      : Node_Access := Invalid_Node_Access;
            begin
               if Tree.ID (Children (1)) = +rhs_item_list_ID then
                  RHS_Item_List := Children (1);
                  if Children'Last > 1 then
                     Action_1 := Children (2);
                  end if;
                  if Children'Last > 2 then
                     Action_2 := Children (3);
                  end if;

               else
                  Attr_List := Children (1);
                  RHS_Item_List := Children (2);
                  if Children'Last > 2 then
                     Action_1 := Children (3);
                  end if;
                  if Children'Last > 3 then
                     Action_2 := Children (4);
                  end if;
               end if;

               RHS.Associativity := Get_Associativity (Data, Tree, Attr_List);
               RHS.Precedence    := Get_Precedence (Data, Tree, Attr_List);

               for I of Tree.Get_IDs (RHS_Item_List, +rhs_element_ID) loop
                  declare
                     Orig_Token_Index : constant SAL.Base_Peek_Type :=
                       (if RHS.Orig_EBNF_RHS or Tree.Augmented (I) = null then 0
                        else WisiToken_Grammar_Runtime.Augmented (Tree.Augmented (I).all).Orig_Token_Index);
                  begin
                     --  We don't check for non-zero Orig_Token_Index here; that just
                     --  indicates it's a new item. See subprograms.wy compilation_unit.

                     case Tree.RHS_Index (I) is
                     when 0 =>

                        --  rhs_item
                        RHS.Tokens.Append
                          (WisiToken.BNF.Labeled_Token'
                             (Label            => +"",
                              Orig_Token_Index => Orig_Token_Index,
                              Identifier => +Get_Text (Data, Tree, Tree.Child (I, 1))));

                     when 1 =>
                        --  IDENTIFIER = rhs_item
                        declare
                           Label : constant String := Get_Text (Data, Tree, Tree.Child (I, 1));
                        begin
                           RHS.Tokens.Append
                             (WisiToken.BNF.Labeled_Token'
                                (Label            => +Label,
                                 Orig_Token_Index => Orig_Token_Index,
                                 Identifier       => +Get_Text (Data, Tree, Tree.Child (I, 3))));

                           if (for all L of Labels => -L /= Label) then
                              Labels.Append (+Label);
                           end if;
                        end;

                     when others =>
                        WisiToken.Syntax_Trees.LR_Utils.Raise_Programmer_Error
                          ("Get_RHS; unimplemented token", Tree, I);
                     end case;
                  end;
               end loop;

               if Action_1 /= Invalid_Node_Access then
                  declare
                     Text : constant String := Get_Text (Data, Tree, Action_1);
                  begin
                     if Text'Length > 0 and (for some C of Text => C /= ' ') then
                        RHS.Post_Parse_Action := +Text;
                        Data.Post_Parse_Action_Count := Data.Post_Parse_Action_Count + 1;
                     end if;
                  end;
               end if;

               if Action_2 /= Invalid_Node_Access then
                  RHS.In_Parse_Action := +Get_Text (Data, Tree, Action_2);
                  Data.In_Parse_Action_Count := Data.In_Parse_Action_Count + 1;
               end if;
            end;
         end if;
      end return;
   exception
   when SAL.Programmer_Error =>
      raise;
   when E : others =>
      if Debug_Mode then
         raise;
      else
         declare
            use Ada.Exceptions;
         begin
            WisiToken.Syntax_Trees.LR_Utils.Raise_Programmer_Error
              ("Get_RHS: " & Exception_Name (E) & ": " & Exception_Message (E), Tree, Token);

            --  WORKAROUND; GNAT pro_22.0w-20201222 ignores 'pragma
            --  no_return' on Raise_Programmer_Error; uncomment 'raise' for that
            --  compiler.
            --
            --  raise;
         end;
      end if;
   end Get_RHS;

   procedure Get_Right_Hand_Sides
     (Data             : in out User_Data_Type;
      Tree             : in out WisiToken.Syntax_Trees.Tree;
      Right_Hand_Sides : in out WisiToken.BNF.RHS_Lists.List;
      Labels           : in out WisiToken.BNF.String_Arrays.Vector;
      Token            : in     WisiToken.Syntax_Trees.Valid_Node_Access)
   with Pre => Tree.ID (Token) = +rhs_list_ID
   is
      Tokens : constant Syntax_Trees.Node_Access_Array := Tree.Children (Token);
   begin
      case Tree.RHS_Index (Token) is
      when 0 =>
         --  | rhs
         if not Data.Ignore_Lines then
            Right_Hand_Sides.Append (Get_RHS (Data, Tree, Labels, Tokens (1)));
         end if;

      when 1 =>
         --  | rhs_list BAR rhs
         Get_Right_Hand_Sides (Data, Tree, Right_Hand_Sides, Labels, Tokens (1));

         if not Data.Ignore_Lines then
            Right_Hand_Sides.Append (Get_RHS (Data, Tree, Labels, Tokens (3)));
         end if;

      when 2 | 4 =>
         --  | rhs_list PERCENT (IF | ELSIF) IDENTIFIER EQUAL IDENTIFIER
         Get_Right_Hand_Sides (Data, Tree, Right_Hand_Sides, Labels, Tokens (1));
         Start_If_1 (Data, Tree, Tokens (4), Tokens (6));

      when 3 | 5 =>
         --  | rhs_list PERCENT (IF | ELSIF) IDENTIFIER IN IDENTIFIER_BAR_list
         Get_Right_Hand_Sides (Data, Tree, Right_Hand_Sides, Labels, Tokens (1));
         Start_If_1 (Data, Tree, Tokens (4), Tokens (6));

      when 6 =>
         --  | rhs_list PERCENT END IF
         Get_Right_Hand_Sides (Data, Tree, Right_Hand_Sides, Labels, Tokens (1));
         Data.Ignore_Lines := False;

      when others =>
         WisiToken.Syntax_Trees.LR_Utils.Raise_Programmer_Error ("Get_Right_Hand_Sides", Tree, Token);
      end case;
   end Get_Right_Hand_Sides;

   ----------
   --  Public subprograms, declaration order

   overriding
   function Copy_Augmented
     (User_Data : in User_Data_Type;
      Augmented : in not null WisiToken.Syntax_Trees.Augmented_Class_Access)
     return WisiToken.Syntax_Trees.Augmented_Class_Access
   is
      Old_Aug : WisiToken_Grammar_Runtime.Augmented renames Augmented_Access (Augmented).all;
      New_Aug : constant Augmented_Access := new WisiToken_Grammar_Runtime.Augmented'(Old_Aug);
   begin
      return WisiToken.Syntax_Trees.Augmented_Class_Access (New_Aug);
   end Copy_Augmented;

   overriding
   function Image_Augmented (Item : in Augmented) return String
   --  This is for debugging, so it is only updated to match current code
   --  when needed for a debugging session.
   is
      use all type SAL.Base_Peek_Type;
   begin
      return
        "(" &
        (if Item.EBNF then "EBNF, " else "") &
        (if Item.Auto_Token_Labels then "Auto_Token_Labels, " else "") &
        (if Item.Orig_EBNF_RHS then "Orig_EBNF_RHS, " else "") &
        (if not Item.Orig_EBNF_RHS and Item.EBNF_RHS_Index /= Natural'Last
         then "EBNF_RHS_Index =>" & Item.EBNF_RHS_Index'Image & ", "
         else "") &
        (if Item.Orig_Token_Index /= 0 then "Orig_Token_Index =>" & Item.Orig_Token_Index'Image & ", " else "") &
        ")";
   end Image_Augmented;

   procedure Reset
     (Data        : in out User_Data_Type;
      User_Lexer  : in     WisiToken.BNF.Lexer_Type;
      User_Parser : in     WisiToken.BNF.Generate_Algorithm;
      Phase       : in     Action_Phase)
   is begin
      Data.User_Parser := User_Parser;
      Data.User_Lexer  := User_Lexer;
      Data.Phase       := Phase;

      if Phase = Meta then
         WisiToken.BNF.Free (Data.Generate_Set);
         Data.EBNF_Ok     := False;
         Data.Meta_Syntax := Unknown;
         Data.Precedence_Map.Clear;
         Data.Precedence_Inverse_Map.Clear;
         Data.Precedence_Lists.Clear;
      end if;

      Data.Raw_Code := (others => <>);

      Data.Language_Params :=
        (Case_Insensitive    => Data.Language_Params.Case_Insensitive,
         Error_Recover       => Data.Language_Params.Error_Recover,
         others              => <>);

      Data.Tokens :=
        (Virtual_Identifiers => Data.Tokens.Virtual_Identifiers,
         others              => <>);

      Data.Suppress.Clear;
      Data.Conflicts.Clear;
      Data.McKenzie_Recover        := (others => <>);
      Data.Rule_Count              := 0;
      Data.Post_Parse_Action_Count := 0;
      Data.In_Parse_Action_Count   := 0;
      Data.Label_Count             := 0;
      Data.If_Lexer_Present        := False;
      Data.If_Parser_Present       := False;
      Data.Ignore_Lines            := False;
   end Reset;

   overriding procedure Initialize_Actions
     (Data : in out User_Data_Type;
      Tree : in     WisiToken.Syntax_Trees.Tree'Class)
   is begin
      null;
   end Initialize_Actions;

   function Get_Lexer_Set
     (User_Data : in out User_Data_Type;
      Tree      : in out WisiToken.Syntax_Trees.Tree;
      Node      : in     Syntax_Trees.Valid_Node_Access)
     return WisiToken.BNF.Lexer_Set
   is
      use WisiToken.BNF;
   begin
      return Result : Lexer_Set := (others => False) do
         if Tree.ID (Node) = +IDENTIFIER_ID then
            Result (To_Lexer (Get_Text (User_Data, Tree, Node))) := True;
         else
            declare
               use WisiToken.Syntax_Trees.LR_Utils;
               List : constant Constant_List := Creators.Create_List
                 (Tree, Node, +IDENTIFIER_BAR_list_ID, +IDENTIFIER_ID);
            begin
               for Item of List loop
                  Result (To_Lexer (Get_Text (User_Data, Tree, Item))) := True;
               end loop;
            end;
         end if;
      end return;
   end Get_Lexer_Set;

   function Get_Generate_Algorithm_Set
     (User_Data : in out User_Data_Type;
      Tree      : in out WisiToken.Syntax_Trees.Tree;
      Node      : in     Syntax_Trees.Valid_Node_Access)
     return WisiToken.BNF.Generate_Algorithm_Set
   is
      use WisiToken.BNF;
   begin
      return Result : Generate_Algorithm_Set := (others => False) do
         if Tree.ID (Node) = +IDENTIFIER_ID then
            Result (To_Generate_Algorithm (Get_Text (User_Data, Tree, Node))) := True;
         else
            declare
               use WisiToken.Syntax_Trees.LR_Utils;
               List : constant Constant_List := Creators.Create_List
                 (Tree, Node, +IDENTIFIER_BAR_list_ID, +IDENTIFIER_ID);
            begin
               for Item of List loop
                  Result (To_Generate_Algorithm (Get_Text (User_Data, Tree, Item))) := True;
               end loop;
            end;
         end if;
      end return;
   end Get_Generate_Algorithm_Set;

   procedure Start_If
     (User_Data : in out WisiToken.Syntax_Trees.User_Data_Type'Class;
      Tree      : in out WisiToken.Syntax_Trees.Tree;
      Nonterm   : in     WisiToken.Syntax_Trees.Valid_Node_Access)
   is begin
      --  all phases
      Start_If_1 (User_Data_Type (User_Data), Tree, Tree.Child (Nonterm, 3), Tree.Child (Nonterm, 5));
   end Start_If;

   procedure End_If (User_Data : in out WisiToken.Syntax_Trees.User_Data_Type'Class)
   is
      Data : User_Data_Type renames User_Data_Type (User_Data);
   begin
      --  all phases
      Data.Ignore_Lines := False;
   end End_If;

   procedure Add_Declaration
     (User_Data : in out WisiToken.Syntax_Trees.User_Data_Type'Class;
      Tree      : in out WisiToken.Syntax_Trees.Tree;
      Nonterm   : in     WisiToken.Syntax_Trees.Valid_Node_Access)
   is
      use all type Ada.Strings.Unbounded.Unbounded_String;
      use all type SAL.Base_Peek_Type;
      use all type WisiToken.Syntax_Trees.Node_Label;

      Data : User_Data_Type renames User_Data_Type (User_Data);

      function Token_Byte_Region (Index : in SAL.Peek_Type) return Buffer_Region
      is
         Child : constant Syntax_Trees.Valid_Node_Access := Tree.Child (Nonterm, Index);
      begin
         if Tree.Label (Child) /= WisiToken.Syntax_Trees.Source_Terminal then
            raise SAL.Programmer_Error with "token at " & Image
              (Tree.Byte_Region (Child, Trailing_Non_Grammar => False)) &
              " is a " & WisiToken.Syntax_Trees.Node_Label'Image (Tree.Label (Child)) &
              ", expecting Source_Terminal";
         else
            return Tree.Byte_Region (Child, Trailing_Non_Grammar => False);
         end if;
      end Token_Byte_Region;

      function Enum_ID (Index : in SAL.Peek_Type) return Token_Enum_ID
      is (To_Token_Enum (Tree.ID (Tree.Child (Nonterm, Index))));

   begin
      if Data.Phase = Meta then
         if Tree.Label (Tree.Child (Nonterm, 2)) = WisiToken.Syntax_Trees.Source_Terminal then
            case Enum_ID (2) is
            when IDENTIFIER_ID =>
               declare
                  Kind : constant String := Tree.Lexer.Buffer_Text (Token_Byte_Region (2));
               begin
                  if Kind = "case_insensitive" then
                     Data.Language_Params.Case_Insensitive := True;

                  elsif Kind = "generate" then
                     declare
                        Children : constant Syntax_Trees.Valid_Node_Access_Array := Tree.Get_Terminals
                          (Tree.Child (Nonterm, 3));
                        Tuple    : WisiToken.BNF.Generate_Tuple;
                     begin
                        Tuple.Gen_Alg  := WisiToken.BNF.To_Generate_Algorithm
                          (Get_Text (Data, Tree, Children (1)));
                        if Children'Last >= 2 then
                           Tuple.Out_Lang := WisiToken.BNF.To_Output_Language
                             (Get_Text (Data, Tree, Children (2)));
                        end if;
                        for I in 3 .. SAL.Base_Peek_Type (Children'Length) loop
                           declare
                              Text : constant String := WisiToken.BNF.To_Lower (Get_Text (Data, Tree, Children (I)));
                           begin
                              if Text = "text_rep" then
                                 Tuple.Text_Rep := True;

                              elsif (for some I of WisiToken.BNF.Lexer_Image => Text = I.all) then
                                 Tuple.Lexer := WisiToken.BNF.To_Lexer (Text);

                              elsif WisiToken.BNF.Is_Valid_Interface (Text) then
                                 Tuple.Interface_Kind := WisiToken.BNF.Valid_Interface'Value (Text);
                              else
                                 Put_Error (Tree.Error_Message (Children (I), "invalid generate param '" & Text & "'"));
                              end if;
                           end;
                        end loop;
                        WisiToken.BNF.Add (Data.Generate_Set, Tuple);
                     end;

                  elsif Kind'Length > 8 and then Kind (Kind'First .. Kind'First + 7) = "mckenzie" then
                     Data.Language_Params.Error_Recover := True;

                  elsif Kind = "meta_syntax" then
                     if Data.Meta_Syntax = Unknown then
                        --  Don't overwrite; somebody set it for a reason.
                        declare
                           Value_Str : constant String := WisiToken.BNF.To_Lower
                             (Get_Text (Data, Tree, Tree.Child (Nonterm, 3)));
                        begin
                           if Value_Str = "bnf" then
                              Data.Meta_Syntax := BNF_Syntax;
                           elsif Value_Str = "ebnf" then
                              Data.Meta_Syntax := EBNF_Syntax;
                              Set_EBNF (Tree, Tree.Find_Ancestor (Tree.Child (Nonterm, 2), +declaration_ID));

                           else
                              Put_Error ("invalid value for %meta_syntax; must be BNF | EBNF.");
                           end if;
                        end;
                     end if;

                  elsif Kind = "precedence" then
                     --  Translate_To_BNF needs this done.
                     declare
                        use WisiToken.Syntax_Trees.LR_Utils;
                        Name_List : constant Constant_List := Creators.Create_List
                          (Tree, Tree.Child (Nonterm, 3), +declaration_item_list_ID, +declaration_item_ID);
                        P_List : WisiToken.Precedence_Lists.List;
                     begin
                        for Item of Name_List loop
                           declare
                              Name  : constant String                 := Get_Text (Data, Tree, Item);
                              Found : constant Precedence_Maps.Cursor := Data.Precedence_Map.Find (Name);
                              P_ID  : WisiToken.Precedence_ID;
                           begin
                              if not Precedence_Maps.Has_Element (Found)  then
                                 P_ID := 1 + WisiToken.Base_Precedence_ID (Data.Precedence_Map.Length);
                                 Data.Precedence_Map.Insert (Name, P_ID);
                                 Data.Precedence_Inverse_Map.Append (+Name);
                              else
                                 P_ID := Data.Precedence_Map (Found);
                              end if;
                              P_List.Append (P_ID);
                           end;
                        end loop;
                        Data.Precedence_Lists.Append (P_List);
                     end;

                  end if;
               end;
            when others =>
               null;
            end case;
         end if;
         return;
      end if;

      --  Add declaration to User_Data.Generate_Set, Language_Params,
      --  Tokens, Conflicts, or McKenzie_Recover.

      if Data.Ignore_Lines then
         return;
      end if;

      case Enum_ID (2) is
      --  Same order as declaration rhs_list in wisitoken_grammar.wy
      when Wisitoken_Grammar_Actions.TOKEN_ID | NON_GRAMMAR_ID =>
         declare
            --  % TOKEN < kind > name value [repair_image]
            --  1 2     3 4    5 6    7      8
            Kind  : constant String := Get_Text (Data, Tree, Tree.Child (Nonterm, 4));
            Name  : constant String := Get_Text (Data, Tree, Tree.Child (Nonterm, 6));
            Value : constant String :=
              (if Tree.Child_Count (Nonterm) >= 7 then Get_Text (Data, Tree, Tree.Child (Nonterm, 7)) else "");

            Repair_Image : constant String :=
              (if Tree.Child_Count (Nonterm) = 8 then Get_Text (Data, Tree, Tree.Child (Nonterm, 8)) else "");
         begin
            if Kind = "delimited_text" or
              Kind = "comment-one-line"
            then
               if Value = Repair_Image then
                  Put_Error (Tree.Error_Message (Nonterm, "start, end delimiters must be different"));
               end if;
            end if;

            if Enum_ID (2) = Wisitoken_Grammar_Actions.TOKEN_ID then
               WisiToken.BNF.Add_Token
                 (Data.Tokens.Tokens,
                  Kind         => Kind,
                  Name         => Name,
                  Value        => Value,
                  Repair_Image => Repair_Image);
            else
               WisiToken.BNF.Add_Token
                 (Data.Tokens.Non_Grammar,
                  Kind         => Kind,
                  Name         => Name,
                  Value        => Value,
                  Repair_Image => Repair_Image);
            end if;
         end;

      when KEYWORD_ID =>
         --  % TOKEN name value
         --  1 2     3    4
         Data.Tokens.Keywords.Append
           ((Name  => +Get_Text (Data, Tree, Tree.Child (Nonterm, 3)),
             Value => +Get_Text (Data, Tree, Tree.Child (Nonterm, 4))));

      when CODE_ID =>
         declare
            Location : WisiToken.BNF.Raw_Code_Location;

            --  % CODE identifier_list RAW_CODE
            --  1 2    3               4
            --
            --  identifier_list = "action spec context"
            --  identifier_list children = identifier_list IDENTIFIER_ID
            --  children = identifier_list IDENTIFIER_ID
            --  children = IDENTIFIER_ID
            Loc_List : constant Syntax_Trees.Valid_Node_Access_Array := Get_Code_Location_List (Tree, Nonterm);

            function Get_Loc (Index : in SAL.Peek_Type) return String
            is (Tree.Lexer.Buffer_Text (Tree.Byte_Region (Loc_List (Index), Trailing_Non_Grammar => False)));

         begin
            if Get_Loc (Loc_List'First) = "actions" then
               if (Get_Loc (2) = "spec" or Get_Loc (2) = "body") and
                 (Get_Loc (3) = "context" or Get_Loc (3) = "pre" or Get_Loc (3) = "post")
               then
                  Location :=
                    (if Get_Loc (2) = "spec" then
                       (if Get_Loc (3) = "context" then WisiToken.BNF.Actions_Spec_Context
                        elsif Get_Loc (3) = "pre" then WisiToken.BNF.Actions_Spec_Pre
                        elsif Get_Loc (3) = "post" then WisiToken.BNF.Actions_Spec_Post
                        else raise SAL.Programmer_Error)

                     elsif Get_Loc (2) = "body" then
                       (if Get_Loc (3) = "context" then WisiToken.BNF.Actions_Body_Context
                        elsif Get_Loc (3) = "pre" then WisiToken.BNF.Actions_Body_Pre
                        elsif Get_Loc (3) = "post" then WisiToken.BNF.Actions_Body_Post
                        else raise SAL.Programmer_Error)

                     else raise SAL.Programmer_Error);
               else
                  Put_Error (Tree.Error_Message (Loc_List (2), "expecting {spec | body} {context | pre | post}"));
               end if;

            elsif Get_Loc (Loc_List'First) = "copyright_license" then
               Location := WisiToken.BNF.Copyright_License;

            else
               Put_Error (Tree.Error_Message (Loc_List (Loc_List'First), "expecting {actions | copyright_license}"));
            end if;

            Data.Raw_Code (Location) := WisiToken.BNF.Split_Lines (Get_Text (Data, Tree, Tree.Child (Nonterm, 4)));
         end;

      when CONFLICT_ID | CONFLICT_RESOLUTION_ID =>
         declare
            --  % CONFLICT conflict_item_list ON TOKEN on_symbol [: resolution]
            --  1 2        3                  4  5     6          7 8
            --
            --  conflict_item_list : action LHS (| action LHS)*
            --  conflict_item_list : LHS*

            Conflict_Items : constant Syntax_Trees.Valid_Node_Access_Array := Tree.Get_Terminals
              (Tree.Child (Nonterm, 3));

            Conflict : BNF.Conflict;
         begin
            Conflict.Source_Line := Tree.Line_Region (Nonterm, Trailing_Non_Grammar => True).First;

            if Conflict_Items'Length < 3 or else
              Tree.ID (Conflict_Items (3)) /= +BAR_ID
            then
               --  Tree_Sitter format
               for LHS of Conflict_Items loop
                  Conflict.Items.Append
                    ((Name  => +"",
                      Value => +Get_Text (Data, Tree, LHS)));
               end loop;

            else
               --  wisi format
               declare
                  I : SAL.Peek_Type := 1;
               begin
                  loop
                     Conflict.Items.Append
                       ((Name  => +Get_Text (Data, Tree, Conflict_Items (I)),
                         Value => +Get_Text (Data, Tree, Conflict_Items (I + 1))));

                     I := I + 2;
                     exit when I > Conflict_Items'Last;
                     I := I + 1;
                  end loop;
               end;

               Conflict.On := +Get_Text (Data, Tree, Tree.Child (Nonterm, 6));
            end if;

            if Tree.Child_Count (Nonterm) = 8 then
               Conflict.Resolution := +Get_Text (Data, Tree, Tree.Child (Nonterm, 8));
            end if;
            Data.Conflicts.Append (Conflict);
         end;

      when IDENTIFIER_ID =>
         declare
            Kind : constant String := Tree.Lexer.Buffer_Text (Token_Byte_Region (2));
         begin
            --  Alphabetical by Kind

            if Kind = "case_insensitive" then
               --  Not in phase Other
               null;

            elsif Kind = "end" then
               --  matching '%if' specified current lexer.
               null;

            elsif Kind = "elisp_face" then
               Data.Tokens.Faces.Append (Get_Text (Data, Tree, Tree.Child (Nonterm, 3), Strip_Quotes => True));

            elsif Kind = "elisp_indent" then
               declare
                  use WisiToken.Syntax_Trees.LR_Utils;

                  Items : constant Constant_List := Creators.Create_List
                    (Tree, Tree.Child (Nonterm, 3), +declaration_item_list_ID, +declaration_item_ID);
                  Iter : constant Constant_Iterator := Iterate_Constant (Items);
                  Item : Cursor := Items.First;
                  Elisp_Name : constant String := Get_Text (Data, Tree, Items (Item), Strip_Quotes => True);
               begin
                  Item := Iter.Next (Item);
                  declare
                     Ada_Name             : constant String := Get_Text (Data, Tree, Items (Item));
                     Function_Args_Region : Buffer_Region   := Null_Buffer_Region;
                  begin
                     Item := Iter.Next (Item);
                     if Has_Element (Item) then
                        Function_Args_Region := Tree.Byte_Region (Items (Item), Trailing_Non_Grammar => False);
                        loop
                           Item := Iter.Next (Item);
                           exit when not Has_Element (Item);

                           Function_Args_Region.Last := Tree.Byte_Region
                             (Items (Item), Trailing_Non_Grammar => False).Last;
                        end loop;
                     end if;

                     Data.Tokens.Indents.Insert
                       (Key      => +Elisp_Name,
                        New_Item =>
                          (Name  => +Ada_Name,
                           Value =>
                             +(if Function_Args_Region = Null_Buffer_Region
                               then ""
                               else Tree.Lexer.Buffer_Text (Function_Args_Region))));
                  end;
               end;

            elsif Kind = "elisp_action" then
               Data.Tokens.Actions.Insert
                 (Key      => +Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 2),
                  New_Item =>
                    (Name  => +Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 1),   -- post-parse action
                     Value => +Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 3))); -- Ada name

            elsif Kind = "end_names_optional_option" then
               Data.Language_Params.End_Names_Optional_Option := +Get_Text (Data, Tree, Tree.Child (Nonterm, 3));

            elsif Kind = "escape_delimiter_doubled" then
               Data.Tokens.Escape_Delimiter_Doubled.Append
                 (Get_Text (Data, Tree, Tree.Child (Nonterm, 3), Strip_Quotes => True));

            elsif Kind = "generate" then
               --  Not in Other phase
               null;

            elsif Kind = "language_runtime" then
               Data.Language_Params.Language_Runtime_Name :=
                 +Get_Text (Data, Tree, Tree.Child (Nonterm, 3), Strip_Quotes => True);

            elsif Kind = "max_parallel" then
               Data.Max_Parallel := SAL.Base_Peek_Type'Value (Get_Text (Data, Tree, Tree.Child (Nonterm, 3)));

            elsif Kind = "mckenzie_check_limit" then
               Data.McKenzie_Recover.Check_Limit := Syntax_Trees.Sequential_Index'Value
                 (Get_Text (Data, Tree, Tree.Child (Nonterm, 3)));

            elsif Kind = "mckenzie_check_delta_limit" then
               Data.McKenzie_Recover.Check_Delta_Limit := Integer'Value
                 (Get_Text (Data, Tree, Tree.Child (Nonterm, 3)));

            elsif Kind = "mckenzie_cost_default" then
               if Tree.Get_Terminals (Tree.Child (Nonterm, 3))'Length /= 4 then
                  Put_Error
                    (Tree.Error_Message
                      (Tree.Child (Nonterm, 3),
                       "too " & (if Tree.Get_Terminals (Tree.Child (Nonterm, 3))'Length > 4 then "many" else "few") &
                         " default costs; should be 'insert, delete, push back, ignore check fail'."));
               end if;

               Data.McKenzie_Recover.Default_Insert          := Natural'Value
                 (Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 1));
               Data.McKenzie_Recover.Default_Delete_Terminal := Natural'Value
                 (Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 2));
               Data.McKenzie_Recover.Default_Push_Back       := Natural'Value
                 (Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 3));
               Data.McKenzie_Recover.Ignore_Check_Fail       := Natural'Value
                 (Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 4));

            elsif Kind = "mckenzie_cost_delete" then
               Data.McKenzie_Recover.Delete.Append
                 ((+Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 1),
                   +Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 2)));

            elsif Kind = "mckenzie_cost_fast_forward" then
               Data.McKenzie_Recover.Fast_Forward :=
                 Integer'Value (Get_Text (Data, Tree, Tree.Child (Nonterm, 3)));

            elsif Kind = "mckenzie_cost_insert" then
               Data.McKenzie_Recover.Insert.Append
                 ((+Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 1),
                   +Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 2)));

            elsif Kind = "mckenzie_cost_matching_begin" then
               Data.McKenzie_Recover.Matching_Begin :=
                 Integer'Value (Get_Text (Data, Tree, Tree.Child (Nonterm, 3)));

            elsif Kind = "mckenzie_cost_push_back" then
               Data.McKenzie_Recover.Push_Back.Append
                 ((+Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 1),
                   +Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 2)));

            elsif Kind = "mckenzie_cost_undo_reduce" then
               Data.McKenzie_Recover.Undo_Reduce.Append
                 ((+Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 1),
                   +Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 2)));

            elsif Kind = "mckenzie_enqueue_limit" then
               Data.McKenzie_Recover.Enqueue_Limit := Natural'Value (Get_Text (Data, Tree, Tree.Child (Nonterm, 3)));

            elsif Kind = "mckenzie_minimal_complete_cost_delta" then
               Data.McKenzie_Recover.Minimal_Complete_Cost_Delta :=
                 Integer'Value (Get_Text (Data, Tree, Tree.Child (Nonterm, 3)));

            elsif Kind = "mckenzie_zombie_limit" then
               Data.McKenzie_Recover.Zombie_Limit := Integer'Value
                 (Get_Text (Data, Tree, Tree.Child (Nonterm, 3)));

            elsif Kind = "meta_syntax" then
               --  not in Other phase
               null;

            elsif Kind = "no_enum" then
               Data.Language_Params.Declare_Enums := False;

            elsif Kind = "no_language_runtime" then
               Data.Language_Params.Use_Language_Runtime := False;

            elsif Kind = "no_error_recover" then
               Data.Language_Params.Error_Recover      := False;
               Data.Language_Params.Recursion_Strategy := None;

            elsif Kind = "partial_recursion" then
               Data.Language_Params.Recursion_Strategy := Partial;

            elsif Kind = "precedence" then
               --  Done in meta phase
               null;

            elsif Kind = "start" then
               Data.Language_Params.Start_Token := +Get_Text (Data, Tree, Tree.Child (Nonterm, 3));

            elsif Kind = "suppress" then
               Data.Suppress.Append
                 ((Name  => +Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 1),
                   Value => +Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 2, Strip_Quotes => True)));

            elsif Kind = "lexer_regexp" then
               Data.Tokens.Lexer_Regexps.Append
                 ((+Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 1),
                   +Get_Child_Text (Data, Tree, Tree.Child (Nonterm, 3), 2)));

            else
               Put_Error (Tree.Error_Message (Tree.Child (Nonterm, 2), "unexpected syntax"));
            end if;
         end;

      when others =>
         Put_Error (Tree.Error_Message (Tree.Child (Nonterm, 2), "unexpected syntax"));
      end case;

   end Add_Declaration;

   procedure Add_Nonterminal
     (User_Data : in out WisiToken.Syntax_Trees.User_Data_Type'Class;
      Tree      : in out WisiToken.Syntax_Trees.Tree;
      Nonterm   : in     WisiToken.Syntax_Trees.Valid_Node_Access)
   is
      use all type Ada.Containers.Count_Type;
      use WisiToken.Syntax_Trees;

      Data : User_Data_Type renames User_Data_Type (User_Data);

      LHS_Node   : constant Valid_Node_Access := Tree.Child (Nonterm, 1);
      LHS_String : constant String            := Get_Text (Data, Tree, LHS_Node);

      Attr_List : constant Node_Access :=
        (if Tree.ID (Tree.Child (Nonterm, 2)) = +attribute_list_ID
         then Tree.Child (Nonterm, 2)
         else Invalid_Node_Access);

      Right_Hand_Sides : WisiToken.BNF.RHS_Lists.List;
      Labels           : WisiToken.BNF.String_Arrays.Vector;

      function Is_Optimized_List return Boolean
      is begin
         if Data.User_Parser not in WisiToken.BNF.LR_Generate_Algorithm then
            return False;
         end if;
         --  From optimized_list.wy:
         --  declarations
         --  : declaration
         --  | declarations declaration
         --  | declarations declarations
         --  ;
         --
         --  From ada_lite_ebnf_bnf.wy
         --
         --  optimized list with separator:
         --  term
         --    : factor
         --    | term multiplying_operator factor
         --    | term multiplying_operator term
         --    ;
         --
         --  AND_relation_list
         --    : AND relation
         --    | AND_relation_list AND relation
         --    | AND_relation_list AND_relation_list
         --    ;
         --
         --  ELSIF_expression_list
         --    : ELSIF expression THEN sequence_of_statements
         --    | ELSIF_expression_list ELSIF expression THEN sequence_of_statements
         --    | ELSIF_expression_list ELSIF_expression_list
         --    ;

         if Right_Hand_Sides.Length /= 3 then
            return False;
         end if;

         declare
            use Ada.Containers;
            use Ada.Strings.Unbounded;
            use WisiToken.BNF.RHS_Lists;

            RHS                 : Cursor     := Right_Hand_Sides.First;
            Element             : Unbounded_String;
            Element_Token_Count : Count_Type := 0;
            Has_Separator       : Boolean    := False;
            Separator           : Unbounded_String;
         begin
            for Tok of Right_Hand_Sides (RHS).Tokens loop
               Append (Element, Tok.Identifier);
               Element_Token_Count := @ + 1;
            end loop;

            Next (RHS);
            if -Right_Hand_Sides (RHS).Tokens (1).Identifier /= LHS_String then
               return False;
            end if;

            if Element_Token_Count = 1 then
               case Right_Hand_Sides (RHS).Tokens.Length is
               when 2 =>
                  null;

               when 3 =>
                  Has_Separator := True;
                  Separator     := Right_Hand_Sides (RHS).Tokens (2).Identifier;

               when others =>
                  return False;
               end case;

               if Has_Separator and then Right_Hand_Sides (RHS).Tokens (2).Identifier /= Separator then
                  return False;
               end if;
               if Right_Hand_Sides (RHS).Tokens (Right_Hand_Sides (RHS).Tokens.Last_Index).Identifier /= Element
               then
                  return False;
               end if;
            else
               if Right_Hand_Sides (RHS).Tokens.Length /= 1 + Element_Token_Count then
                  return False;
               end if;

               declare
                  Temp             : Unbounded_String;
                  Temp_Token_Count : Count_Type := 0;
               begin
                  for I in 2 .. Positive_Index_Type (Right_Hand_Sides (RHS).Tokens.Length) loop
                     Append (Temp, Right_Hand_Sides (RHS).Tokens (I).Identifier);
                     Temp_Token_Count := @ + 1;
                  end loop;

                  if Temp /= Element or Temp_Token_Count /= Element_Token_Count then
                     return False;
                  end if;
               end;
            end if;

            Next (RHS);
            if Right_Hand_Sides (RHS).Tokens.Length /= (if Has_Separator then 3 else 2) then
               return False;
            end if;
            if -Right_Hand_Sides (RHS).Tokens (1).Identifier /= LHS_String then
               return False;
            end if;
            if Has_Separator then
               if Right_Hand_Sides (RHS).Tokens (2).Identifier /= Separator then
                  return False;
               end if;
               if Right_Hand_Sides (RHS).Tokens (3).Identifier /= LHS_String then
                  return False;
               end if;
            else
               if Right_Hand_Sides (RHS).Tokens (2).Identifier /= LHS_String then
                  return False;
               end if;
            end if;
            return True;
         end;
      end Is_Optimized_List;

   begin
      if Data.Phase = Meta or Data.Ignore_Lines then
         return;
      end if;

      Data.Rule_Count := Data.Rule_Count + 1;

      Get_Right_Hand_Sides
        (Data, Tree, Right_Hand_Sides, Labels, Tree.Child
           (Nonterm, (if Attr_List = Invalid_Node_Access then 3 else 4)));

      if WisiToken.BNF.Is_Present (Data.Tokens.Rules, LHS_String) then
         case Tree.Label (LHS_Node) is
         when Source_Terminal =>
            Put_Error (Tree.Error_Message (LHS_Node, "duplicate nonterm"));

         when Virtual_Identifier =>
            Put_Error (Error_Message (Tree.Lexer.File_Name, 1, 1, "duplicate virtual nonterm '" & LHS_String & "'"));

         when others =>
            WisiToken.Syntax_Trees.LR_Utils.Raise_Programmer_Error ("Add_Nonterminal", Tree, LHS_Node);
         end case;
      else
         Data.Label_Count := Data.Label_Count + Labels.Length;

         declare
            --  Work around "unspecified order" warning; Tree is 'in out' in Get_Precedence.
            Prec : constant WisiToken.Base_Precedence_ID := Get_Precedence (Data, Tree, Attr_List);
         begin
            Data.Tokens.Rules.Append
              ((Left_Hand_Side   => +LHS_String,
                Precedence       => Prec,
                Right_Hand_Sides => Right_Hand_Sides,
                Labels           => Labels,
                Optimized_List   => Is_Optimized_List,
                Source_Line      =>
                  (case Tree.Label (LHS_Node) is
                   when Source_Terminal    => Tree.Line_Region (LHS_Node, Trailing_Non_Grammar => True).First,
                   when Virtual_Identifier => Line_Number_Type'First, -- IMPROVEME: get line from Right_Hand_Sides
                   when others             => raise SAL.Programmer_Error)));
         end;
      end if;
   end Add_Nonterminal;

   procedure Check_EBNF
     (User_Data : in out WisiToken.Syntax_Trees.User_Data_Type'Class;
      Tree      : in     WisiToken.Syntax_Trees.Tree;
      Nonterm   : in     WisiToken.Syntax_Trees.Valid_Node_Access;
      Token     : in     WisiToken.Positive_Index_Type)
   is
      Data : User_Data_Type renames User_Data_Type (User_Data);
   begin
      if Data.Meta_Syntax = EBNF_Syntax then
         Set_EBNF (Tree, Tree.Child (Nonterm, Token));
         return;
      end if;

      case Data.Phase is
      when Meta =>
         raise Grammar_Error with Tree.Error_Message
           (Tree.Child (Nonterm, Token), "EBNF syntax used, but BNF specified; set '%meta_syntax EBNF'");
      when Other =>
         Put_Error
           (Tree.Error_Message (Tree.Child (Nonterm, Token), "untranslated EBNF node") &
              (if Debug_Mode
               then " " & Tree.Image (Tree.Child (Nonterm, Token), Node_Numbers => True, RHS_Index => True)
               else ""));
         raise SAL.Programmer_Error;
      end case;
   end Check_EBNF;

   function Get_Associativity
     (Data      : in     User_Data_Type;
      Tree      : in out WisiToken.Syntax_Trees.Tree;
      Attr_List : in     WisiToken.Syntax_Trees.Node_Access)
     return WisiToken.Associativity
   is
      use WisiToken.Syntax_Trees;
   begin
      if Attr_List = Invalid_Node_Access then
         return WisiToken.None;
      else
         declare
            List : constant LR_Utils.Constant_List := LR_Utils.Creators.Create_List
              (Tree       => Tree,
               Root       => Attr_List,
               List_ID    => +attribute_list_ID,
               Element_ID => +attribute_ID);
         begin
            for Attr of List loop
               if Get_Text (Data, Tree, Tree.Child (Attr, 2)) = "assoc" then
                  declare
                     Name : constant String := Get_Text (Data, Tree, Tree.Child (Attr, 4));
                  begin
                     return WisiToken.Associativity'Value (Name);
                  exception
                  when Constraint_Error =>
                     Put_Error
                       (Tree.Error_Message
                          (Attr_List, "invalid associativity name '" & Name & "'; must be 'left' or 'right'"));
                  end;
               end if;
            end loop;
         end;
         return WisiToken.None;
      end if;
   end Get_Associativity;

   function Get_Precedence
     (Data      : in     User_Data_Type;
      Tree      : in out WisiToken.Syntax_Trees.Tree;
      Attr_List : in     WisiToken.Syntax_Trees.Node_Access)
     return WisiToken.Base_Precedence_ID
   is
      use WisiToken.Syntax_Trees;
   begin
      if Attr_List = Invalid_Node_Access then
         return WisiToken.No_Precedence;
      else
         declare
            List : constant LR_Utils.Constant_List := LR_Utils.Creators.Create_List
              (Tree       => Tree,
               Root       => Attr_List,
               List_ID    => +attribute_list_ID,
               Element_ID => +attribute_ID);
         begin
            for Attr of List loop
               if Get_Text (Data, Tree, Tree.Child (Attr, 2)) = "prec" then
                  declare
                     Name  : constant String                  := Get_Text (Data, Tree, Tree.Child (Attr, 4));
                     Found : constant WisiToken.Precedence_Maps.Cursor := Data.Precedence_Map.Find (Name);
                  begin
                     if WisiToken.Precedence_Maps.Has_Element (Found) then
                        return Data.Precedence_Map (Found);
                     else
                        Put_Error (Tree.Error_Message (Attr_List, "undeclared precedence name '" & Name & "'"));
                     end if;
                  end;
               end if;
            end loop;
         end;
         return WisiToken.No_Precedence;
      end if;
   end Get_Precedence;

   function Get_Text
     (Virtual_Identifiers : in WisiToken.BNF.String_Arrays.Vector;
      Tree                : in WisiToken.Syntax_Trees.Tree;
      Tree_Index          : in WisiToken.Syntax_Trees.Node_Access;
      Strip_Quotes        : in Boolean := False)
     return String
   is
      use all type Syntax_Trees.Node_Label;

      function Strip_Delimiters (Tree_Index : in Syntax_Trees.Valid_Node_Access) return String
      is
         Region : Buffer_Region renames Tree.Byte_Region (Tree_Index, Trailing_Non_Grammar => False);
      begin
         if -Tree.ID (Tree_Index) in RAW_CODE_ID | REGEXP_ID | ACTION_ID then
            --  Strip delimiters. We don't strip leading/trailing spaces to preserve indent.
            return Tree.Lexer.Buffer_Text ((Region.First + 2, Region.Last - 2));

         elsif -Tree.ID (Tree_Index) in STRING_LITERAL_DOUBLE_ID | STRING_LITERAL_SINGLE_ID and Strip_Quotes then
            return Tree.Lexer.Buffer_Text ((Region.First + 1, Region.Last - 1));
         else
            return Tree.Lexer.Buffer_Text (Region);
         end if;
      end Strip_Delimiters;

   begin
      if Tree_Index = Syntax_Trees.Invalid_Node_Access then
         return "<deleted child>";
      end if;

      case Tree.Label (Tree_Index) is
      when Source_Terminal =>
         return Strip_Delimiters (Tree_Index);

      when Virtual_Terminal =>
         --  Terminal keyword inserted during tree edit. We could check for
         --  Identifier, but that will be caught later.
         return Image (Tree.ID (Tree_Index), Wisitoken_Grammar_Actions.Descriptor);

      when Virtual_Identifier =>
         if Strip_Quotes then
            declare
               Quoted : constant String := -Virtual_Identifiers (Tree.Identifier (Tree_Index));
            begin
               return Quoted (Quoted'First + 1 .. Quoted'Last - 1);
            end;
         else
            return -Virtual_Identifiers (Tree.Identifier (Tree_Index));
         end if;

      when Nonterm =>
         declare
            use all type Ada.Strings.Unbounded.Unbounded_String;
            Result       : Ada.Strings.Unbounded.Unbounded_String;
            Tree_Indices : constant Syntax_Trees.Valid_Node_Access_Array := Tree.Get_Terminals (Tree_Index);
            Need_Space   : Boolean                                      := False;
         begin
            for Tree_Index of Tree_Indices loop
               Result := Result & (if Need_Space then " " else "") &
                 Get_Text (Virtual_Identifiers, Tree, Tree_Index, Strip_Quotes);
               Need_Space := True;
            end loop;
            return -Result;
         end;
      end case;
   end Get_Text;

   function Get_Code_Location_List
     (Tree    : in WisiToken.Syntax_Trees.Tree;
      Nonterm : in WisiToken.Syntax_Trees.Valid_Node_Access)
     return Syntax_Trees.Valid_Node_Access_Array
   is
      use all type SAL.Base_Peek_Type;
      use WisiToken.Syntax_Trees;
      Node   : Valid_Node_Access := Tree.Child (Nonterm, 3);
      Result : Valid_Node_Access_Array (1 .. 3) := (others => Dummy_Node);
      First  : SAL.Peek_Type    := Result'Last + 1;
   begin
      loop
         pragma Assert (Tree.ID (Node) = +identifier_list_ID);
         exit when not Tree.Has_Children (Node);
         declare
            Children : constant Node_Access_Array := Tree.Children (Node);
         begin
            if Children'Length = 1 then
               --  identifier_list : IDENTIFIER
               First := First - 1;
               Result (First) := Children (1);
               exit;

            elsif Children'Length = 2 then
               --  identifier_list : identifier_list IDENTIFIER
               First := First - 1;
               Result (First) := Children (2);

               Node := Children (1);
            else
               raise SAL.Programmer_Error;
            end if;
         end;
      end loop;
      return Result (First .. Result'Last);
   end Get_Code_Location_List;

end WisiToken_Grammar_Runtime;
--  Local Variables:
--  ada-case-strict: nil
--  End:
