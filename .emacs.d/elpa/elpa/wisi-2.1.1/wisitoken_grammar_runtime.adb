--  Abstract :
--
--  See spec.
--
--  Copyright (C) 2018 - 2019 Free Software Foundation, Inc.
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

with Ada.Characters.Handling;
with Ada.Exceptions;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with GNAT.Regexp;
with SAL.Generic_Decimal_Image;
with System.Assertions;
with WisiToken.Generate;   use WisiToken.Generate;
with Wisitoken_Grammar_Actions; use Wisitoken_Grammar_Actions;
package body WisiToken_Grammar_Runtime is

   use WisiToken;

   ----------
   --  Body subprograms, misc order

   procedure Raise_Programmer_Error
     (Label : in String;
      Tree  : in WisiToken.Syntax_Trees.Tree;
      Node  : in WisiToken.Syntax_Trees.Node_Index);
   pragma No_Return (Raise_Programmer_Error);

   procedure Raise_Programmer_Error
     (Label : in String;
      Tree  : in WisiToken.Syntax_Trees.Tree;
      Node  : in WisiToken.Syntax_Trees.Node_Index)
   is begin
      raise SAL.Programmer_Error with Label & WisiToken.Syntax_Trees.Node_Index'Image (Node) &
        ":" & Tree.Image (Node, Wisitoken_Grammar_Actions.Descriptor, Include_Children => True);
   end Raise_Programmer_Error;

   function Get_Line
     (Data : in User_Data_Type;
      Tree : in Syntax_Trees.Tree;
      Node : in WisiToken.Syntax_Trees.Valid_Node_Index)
     return WisiToken.Line_Number_Type
   is
      --  Find a source line for Node.

      use WisiToken.Syntax_Trees;

      Temp : Node_Index := Node;
   begin
      loop
         if Tree.Min_Terminal_Index (Temp) = Invalid_Token_Index then
            --  Node is empty or all virtual_identifiers; try parents.
            Temp := Tree.Parent (Temp);
            exit when Temp = Invalid_Node_Index;
         else
            return Data.Terminals.all (Tree.Min_Terminal_Index (Temp)).Line;
         end if;
      end loop;
      return Invalid_Line_Number;
   end Get_Line;

   function Get_Text
     (Data         : in User_Data_Type;
      Tree         : in Syntax_Trees.Tree;
      Tree_Index   : in Syntax_Trees.Valid_Node_Index;
      Strip_Quotes : in Boolean := False)
     return String
   is
      use all type Syntax_Trees.Node_Label;

      function Strip_Delimiters (Tree_Index : in Syntax_Trees.Valid_Node_Index) return String
      is
         Region : Buffer_Region renames Data.Terminals.all (Tree.Terminal (Tree_Index)).Byte_Region;
      begin
         if -Tree.ID (Tree_Index) in RAW_CODE_ID | REGEXP_ID | ACTION_ID then
            --  Strip delimiters. We don't strip leading/trailing spaces to preserve indent.
            return Data.Grammar_Lexer.Buffer_Text ((Region.First + 2, Region.Last - 2));

         elsif -Tree.ID (Tree_Index) in STRING_LITERAL_1_ID | STRING_LITERAL_2_ID and Strip_Quotes then
            return Data.Grammar_Lexer.Buffer_Text ((Region.First + 1, Region.Last - 1));
         else
            return Data.Grammar_Lexer.Buffer_Text (Region);
         end if;
      end Strip_Delimiters;

   begin
      case Tree.Label (Tree_Index) is
      when Shared_Terminal =>
         return Strip_Delimiters (Tree_Index);

      when Virtual_Terminal =>
         --  Terminal keyword inserted during tree edit. We could check for
         --  Identifier, but that will be caught later.
         return Image (Tree.ID (Tree_Index), Wisitoken_Grammar_Actions.Descriptor);

      when Virtual_Identifier =>
         if Strip_Quotes then
            declare
               Quoted : constant String := -Data.Tokens.Virtual_Identifiers (Tree.Identifier (Tree_Index));
            begin
               return Quoted (Quoted'First + 1 .. Quoted'Last - 1);
            end;
         else
            return -Data.Tokens.Virtual_Identifiers (Tree.Identifier (Tree_Index));
         end if;

      when Nonterm =>
         declare
            use all type Ada.Strings.Unbounded.Unbounded_String;
            Result       : Ada.Strings.Unbounded.Unbounded_String;
            Tree_Indices : constant Syntax_Trees.Valid_Node_Index_Array := Tree.Get_Terminals (Tree_Index);
            Need_Space   : Boolean                                      := False;
         begin
            for Tree_Index of Tree_Indices loop
               Result := Result & (if Need_Space then " " else "") &
                 Get_Text (Data, Tree, Tree_Index, Strip_Quotes);
               Need_Space := True;
            end loop;
            return -Result;
         end;
      end case;
   end Get_Text;

   function Get_Child_Text
     (Data         : in User_Data_Type;
      Tree         : in Syntax_Trees.Tree;
      Parent       : in Syntax_Trees.Valid_Node_Index;
      Child        : in SAL.Peek_Type;
      Strip_Quotes : in Boolean := False)
     return String
   is
      Tree_Indices : constant Syntax_Trees.Valid_Node_Index_Array := Tree.Get_Terminals (Parent);
   begin
      return Get_Text (Data, Tree, Tree_Indices (Child), Strip_Quotes);
   end Get_Child_Text;

   procedure Start_If_1
     (Data    : in out User_Data_Type;
      Tree    : in     Syntax_Trees.Tree;
      A_Index : in     Syntax_Trees.Valid_Node_Index;
      B_Index : in     Syntax_Trees.Valid_Node_Index)
   is
      use all type WisiToken.BNF.Generate_Algorithm;
      use all type WisiToken.BNF.Lexer_Type;
   begin
      if "lexer" = Get_Text (Data, Tree, A_Index) then
         Data.If_Lexer_Present := True;
         Data.Ignore_Lines     := Data.User_Lexer /= WisiToken.BNF.To_Lexer (Get_Text (Data, Tree, B_Index));

      elsif "parser" = Get_Text (Data, Tree, A_Index) then
         Data.If_Parser_Present := True;
         Data.Ignore_Lines := Data.User_Parser /= WisiToken.BNF.Generate_Algorithm'Value
           (Get_Text (Data, Tree, B_Index));

      else
         raise Grammar_Error with
           Error_Message
             (Data.Grammar_Lexer.File_Name, Data.Terminals.all (Tree.Min_Terminal_Index (A_Index)).Line,
              "invalid '%if'; must be one of {lexer | parser}");
      end if;
   end Start_If_1;

   function Get_RHS
     (Data   : in out User_Data_Type;
      Tree   : in     Syntax_Trees.Tree;
      Labels : in out WisiToken.BNF.String_Arrays.Vector;
      Token  : in     Syntax_Trees.Valid_Node_Index)
     return WisiToken.BNF.RHS_Type
   is
      use all type WisiToken.Syntax_Trees.Node_Index;
      use all type SAL.Base_Peek_Type;
      Children : constant Syntax_Trees.Valid_Node_Index_Array := Tree.Children (Token);
   begin
      pragma Assert (-Tree.ID (Token) = rhs_ID);

      return RHS : WisiToken.BNF.RHS_Type do
         RHS.Source_Line := Get_Line (Data, Tree, Token);

         if Children'Length > 0 then
            for I of Tree.Get_IDs (Children (1), +rhs_element_ID) loop
               case Tree.RHS_Index (I) is
               when 0 =>
                  --  rhs_item
                  RHS.Tokens.Append
                    ((Label      => +"",
                      Identifier => +Get_Text (Data, Tree, Tree.Child (I, 1))));

               when 1 =>
                  --  IDENTIFIER = rhs_item
                  declare
                     Label : constant String := Get_Text (Data, Tree, Tree.Child (I, 1));
                  begin
                     RHS.Tokens.Append
                       ((Label      => +Label,
                         Identifier => +Get_Text (Data, Tree, Tree.Child (I, 3))));

                     if (for all L of Labels => -L /= Label) then
                        Labels.Append (+Label);
                     end if;
                  end;

               when others =>
                  Raise_Programmer_Error ("Get_RHS; unimplimented token", Tree, I);
               end case;
            end loop;

            if Children'Last >= 2 then
               declare
                  Text : constant String := Get_Text (Data, Tree, Children (2));
               begin
                  if Text'Length > 0 and (for some C of Text => C /= ' ') then
                     RHS.Action := +Text;
                     Data.Action_Count := Data.Action_Count + 1;
                  end if;
               end;
            end if;

            if Children'Last >= 3 then
               RHS.Check := +Get_Text (Data, Tree, Children (3));
               Data.Check_Count := Data.Check_Count + 1;
            end if;
         end if;
      end return;
   exception
   when SAL.Programmer_Error =>
      raise;
   when E : others =>
      declare
         use Ada.Exceptions;
      begin
         Raise_Programmer_Error ("Get_RHS: " & Exception_Name (E) & ": " & Exception_Message (E), Tree, Token);
      end;
   end Get_RHS;

   procedure Get_Right_Hand_Sides
     (Data             : in out User_Data_Type;
      Tree             : in     WisiToken.Syntax_Trees.Tree;
      Right_Hand_Sides : in out WisiToken.BNF.RHS_Lists.List;
      Labels           : in out WisiToken.BNF.String_Arrays.Vector;
      Token            : in     WisiToken.Syntax_Trees.Valid_Node_Index)
   is
      Tokens : constant Syntax_Trees.Valid_Node_Index_Array := Tree.Children (Token);
   begin
      pragma Assert (-Tree.ID (Token) = rhs_list_ID);

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

      when 2 =>
         --  | rhs_list PERCENT IF IDENTIFIER EQUAL IDENTIFIER
         Get_Right_Hand_Sides (Data, Tree, Right_Hand_Sides, Labels, Tokens (1));
         Start_If_1 (Data, Tree, Tokens (4), Tokens (6));

      when 3 =>
         --  | rhs_list PERCENT END IF
         Get_Right_Hand_Sides (Data, Tree, Right_Hand_Sides, Labels, Tokens (1));
         Data.Ignore_Lines := False;

      when others =>
         Raise_Programmer_Error ("Get_Right_Hand_Sides", Tree, Token);
      end case;
   end Get_Right_Hand_Sides;

   ----------
   --  Public subprograms, declaration order

   overriding
   procedure Set_Lexer_Terminals
     (User_Data : in out User_Data_Type;
      Lexer     : in     WisiToken.Lexer.Handle;
      Terminals : in     Base_Token_Array_Access)
   is begin
      User_Data.Grammar_Lexer := Lexer;
      User_Data.Terminals     := Terminals;
   end Set_Lexer_Terminals;

   overriding procedure Reset (Data : in out User_Data_Type)
   is begin
      --  Preserve data set in Phase Meta, or by Set_Lexer_Terminals, or by
      --  wisitoken-bnf-generate.

      --  Preserve Grammar_Lexer
      --  Preserve User_Lexer
      --  Preserve User_Parser
      --  Perserve Generate_Set
      --  Preserve Meta_Syntax
      --  Preserve Phase
      --  Preserve Terminals
      --  Preserve Non_Grammar
      --  EBNF_Nodes handled in Initialize_Actions
      Data.Raw_Code          := (others => <>);
      Data.Language_Params   :=
        (Case_Insensitive => Data.Language_Params.Case_Insensitive,
         others => <>);
      Data.Tokens            :=
        (Virtual_Identifiers => Data.Tokens.Virtual_Identifiers,
         others => <>);
      Data.Conflicts.Clear;
      Data.McKenzie_Recover  := (others => <>);
      Data.Rule_Count        := 0;
      Data.Action_Count      := 0;
      Data.Check_Count       := 0;
      Data.Label_Count       := 0;
      Data.If_Lexer_Present  := False;
      Data.If_Parser_Present := False;
      Data.Ignore_Lines      := False;
   end Reset;

   overriding procedure Initialize_Actions
     (Data : in out User_Data_Type;
      Tree : in     WisiToken.Syntax_Trees.Tree'Class)
   is begin
      Data.EBNF_Nodes.Clear;
      Data.EBNF_Nodes.Set_First_Last (Tree.First_Index, Tree.Last_Index);
   end Initialize_Actions;

   overriding
   procedure Lexer_To_Augmented
     (Data  : in out          User_Data_Type;
      Token : in              WisiToken.Base_Token;
      Lexer : not null access WisiToken.Lexer.Instance'Class)
   is
      pragma Unreferenced (Lexer);
      use all type Ada.Containers.Count_Type;
   begin
      if Token.ID < Wisitoken_Grammar_Actions.Descriptor.First_Terminal then
         --  Non-grammar token
         if Data.Non_Grammar.Length = 0 then
            Data.Non_Grammar.Set_First_Last (0, 0);
         end if;

         if Data.Terminals.Length = 0 then
            Data.Non_Grammar (0).Append (Token);
         else
            Data.Non_Grammar.Set_Last (Data.Terminals.Last_Index);
            Data.Non_Grammar (Data.Terminals.Last_Index).Append (Token);
         end if;
      end if;
   end Lexer_To_Augmented;

   procedure Start_If
     (User_Data : in out WisiToken.Syntax_Trees.User_Data_Type'Class;
      Tree      : in     WisiToken.Syntax_Trees.Tree;
      Tokens    : in     WisiToken.Syntax_Trees.Valid_Node_Index_Array)
   is begin
      --  all phases
      Start_If_1 (User_Data_Type (User_Data), Tree, Tokens (3), Tokens (5));
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
      Tree      : in     WisiToken.Syntax_Trees.Tree;
      Tokens    : in     WisiToken.Syntax_Trees.Valid_Node_Index_Array)
   is
      use all type WisiToken.Syntax_Trees.Node_Label;
      use all type Ada.Strings.Unbounded.Unbounded_String;

      Data : User_Data_Type renames User_Data_Type (User_Data);

      function Token (Index : in SAL.Peek_Type) return Base_Token
      is
         use all type SAL.Base_Peek_Type;
      begin
         if Tokens'Last < Index then
            raise SAL.Programmer_Error;
         elsif Tree.Label (Tokens (Index)) /= WisiToken.Syntax_Trees.Shared_Terminal then
            raise SAL.Programmer_Error with "token at " & Image (Tree.Byte_Region (Tokens (Index))) &
              " is a " & WisiToken.Syntax_Trees.Node_Label'Image (Tree.Label (Tokens (Index))) &
              ", expecting Shared_Terminal";
         else
            return Data.Terminals.all (Tree.Terminal (Tokens (Index)));
         end if;
      end Token;

      function Enum_ID (Index : in SAL.Peek_Type) return Token_Enum_ID
        is (To_Token_Enum (Token (Index).ID));

   begin
      if Data.Phase = Meta then
         if Tree.Label (Tokens (2)) = WisiToken.Syntax_Trees.Shared_Terminal then
            case Enum_ID (2) is
            when IDENTIFIER_ID =>
               declare
                  Kind : constant String := Data.Grammar_Lexer.Buffer_Text (Token (2).Byte_Region);
               begin
                  if Kind = "case_insensitive" then
                     Data.Language_Params.Case_Insensitive := True;

                  elsif Kind = "generate" then
                     declare
                        use all type SAL.Base_Peek_Type;
                        Children : constant Syntax_Trees.Valid_Node_Index_Array := Tree.Get_Terminals (Tokens (3));
                        Tuple    : WisiToken.BNF.Generate_Tuple;
                     begin
                        Tuple.Gen_Alg  := WisiToken.BNF.To_Generate_Algorithm (Get_Text (Data, Tree, Children (1)));
                        if Children'Last >= 2 then
                           Tuple.Out_Lang := WisiToken.BNF.To_Output_Language (Get_Text (Data, Tree, Children (2)));
                        end if;
                        for I in 3 .. SAL.Base_Peek_Type (Children'Length) loop
                           declare
                              Text : constant String := Get_Text (Data, Tree, Children (I));
                           begin
                              if Text = "text_rep" then
                                 Tuple.Text_Rep := True;

                              elsif (for some I of WisiToken.BNF.Lexer_Image => Text = I.all) then
                                 Tuple.Lexer := WisiToken.BNF.To_Lexer (Text);

                              elsif (for some I in WisiToken.BNF.Valid_Interface =>
                                       WisiToken.BNF.To_Lower (Text) = WisiToken.BNF.To_Lower
                                         (WisiToken.BNF.Valid_Interface'Image (I)))
                              then
                                 Tuple.Interface_Kind := WisiToken.BNF.Valid_Interface'Value (Text);
                              else
                                 declare
                                    Token : Base_Token renames Data.Terminals.all (Tree.Terminal (Children (I)));
                                 begin
                                    raise Grammar_Error with Error_Message
                                      (Data.Grammar_Lexer.File_Name, Token.Line, Token.Column,
                                       "invalid generate param '" & Text & "'");
                                 end;
                              end if;
                           end;
                        end loop;
                        WisiToken.BNF.Add (Data.Generate_Set, Tuple);
                     end;

                  elsif Kind = "meta_syntax" then
                     if Data.Meta_Syntax = Unknown then
                        --  Don't overwrite; somebody set it for a reason.
                        declare
                           Value_Str : constant String := WisiToken.BNF.To_Lower (Get_Text (Data, Tree, Tokens (3)));
                        begin
                           if Value_Str = "bnf" then
                              Data.Meta_Syntax := BNF_Syntax;
                           elsif Value_Str = "ebnf" then
                              Data.Meta_Syntax := EBNF_Syntax;
                              Data.EBNF_Nodes (Tree.Find_Ancestor (Tokens (2), +declaration_ID)) := True;

                           else
                              Put_Error ("invalid value for %meta_syntax; must be BNF | EBNF.");
                           end if;
                        end;
                     end if;
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

      case Tree.Label (Tokens (2)) is
      when Syntax_Trees.Nonterm =>
         --  must be token_keyword_non_grammar
         declare
            Children   : Syntax_Trees.Valid_Node_Index_Array renames Tree.Children (Tokens (2));
            Child_1_ID : constant Token_Enum_ID := To_Token_Enum (Tree.ID (Children (1)));
         begin
            case Child_1_ID is
            when Wisitoken_Grammar_Actions.TOKEN_ID =>

               WisiToken.BNF.Add_Token
                 (Data.Tokens.Tokens,
                  Kind  => Get_Text (Data, Tree, Children (3)),
                  Name  => Get_Text (Data, Tree, Tokens (3)),
                  Value => Get_Text (Data, Tree, Tokens (4)));

            when KEYWORD_ID =>

               Data.Tokens.Keywords.Append
                 ((Name  => +Get_Text (Data, Tree, Tokens (3)),
                   Value => +Get_Text (Data, Tree, Tokens (4))));

            when NON_GRAMMAR_ID =>

               WisiToken.BNF.Add_Token
                 (Data.Tokens.Non_Grammar,
                  Kind  => Get_Text (Data, Tree, Children (3)),
                  Name  => Get_Text (Data, Tree, Tokens (3)),
                  Value => Get_Text (Data, Tree, Tokens (4)));

            when others =>
               raise SAL.Programmer_Error;
            end case;
         end;

      when Syntax_Trees.Shared_Terminal =>
         case Enum_ID (2) is
         when CODE_ID =>
            declare
               Location : WisiToken.BNF.Raw_Code_Location;

               --  % code identifier_list raw_code
               --  1 2    3               4
               --
               --  identifier_list = "action spec context"
               --  identifier_list children = identifier_list IDENTIFIER_ID
               --  children = identifier_list IDENTIFIER_ID
               --  children = IDENTIFIER_ID
               function Get_Loc_List return Base_Token_Array
               is
                  use all type SAL.Base_Peek_Type;
                  use WisiToken.Syntax_Trees;
                  Node   : Valid_Node_Index := Tokens (3);
                  Result : Base_Token_Array (1 .. 3);
                  First  : SAL.Peek_Type    := Result'Last + 1;
               begin
                  loop
                     pragma Assert (-Tree.ID (Node) = identifier_list_ID);
                     exit when not Tree.Has_Children (Node);
                     declare
                        Children : constant Valid_Node_Index_Array := Tree.Children (Node);
                     begin
                        if Children'Length = 1 then
                           --  identifier_list : IDENTIFIER
                           First := First - 1;
                           Result (First) := Data.Terminals.all (Tree.Terminal (Children (1)));
                           exit;

                        elsif Children'Length = 2 then
                           --  identifier_list : identifier_list IDENTIFIER
                           First := First - 1;
                           Result (First) := Data.Terminals.all (Tree.Terminal (Children (2)));

                           Node := Children (1);
                        else
                           raise SAL.Programmer_Error;
                        end if;
                     end;
                  end loop;
                  return Result (First .. Result'Last);
               end Get_Loc_List;

               Loc_List : constant Base_Token_Array := Get_Loc_List;

               function Get_Loc (Index : in SAL.Peek_Type) return String
               is (Data.Grammar_Lexer.Buffer_Text (Loc_List (Index).Byte_Region));

            begin
               if Get_Loc (Loc_List'First) = "actions" then
                  Location :=
                    (if Get_Loc (2) = "spec" then
                       (if Get_Loc (3) = "context" then WisiToken.BNF.Actions_Spec_Context
                        elsif Get_Loc (3) = "pre" then WisiToken.BNF.Actions_Spec_Pre
                        elsif Get_Loc (3) = "post" then WisiToken.BNF.Actions_Spec_Post
                        else raise Grammar_Error with
                          Error_Message
                            (Data.Grammar_Lexer.File_Name, Loc_List (2).Line,
                            "expecting {context | pre | post}"))

                     elsif Get_Loc (2) = "body" then
                       (if Get_Loc (3) = "context" then WisiToken.BNF.Actions_Body_Context
                        elsif Get_Loc (3) = "pre" then WisiToken.BNF.Actions_Body_Pre
                        elsif Get_Loc (3) = "post" then WisiToken.BNF.Actions_Body_Post
                        else raise Grammar_Error with
                          Error_Message
                            (Data.Grammar_Lexer.File_Name, Loc_List (2).Line,
                            "expecting {context | pre | post}"))

                     else raise Grammar_Error);

               elsif Get_Loc (Loc_List'First) = "copyright_license" then
                  Location := WisiToken.BNF.Copyright_License;

               else
                  raise Grammar_Error with
                    Error_Message
                      (Data.Grammar_Lexer.File_Name, Loc_List (Loc_List'First).Line,
                       "expecting {actions | copyright_license}");
               end if;

               Data.Raw_Code (Location) := WisiToken.BNF.Split_Lines (Get_Text (Data, Tree, Tokens (4)));
            exception
            when Grammar_Error =>
               Put_Error
                 (Error_Message
                    (Data.Grammar_Lexer.File_Name, Token (2).Line, Token (2).Column,
                     "invalid raw code location; actions {spec | body} {context | pre | post}"));
            end;

         when IDENTIFIER_ID =>
            declare
               Kind : constant String := Data.Grammar_Lexer.Buffer_Text (Token (2).Byte_Region);
            begin
               --  Alphabetical by Kind

               if Kind = "case_insensitive" then
                  --  Not in phase Other
                  null;

               elsif Kind = "conflict" then
                  declare
                     Tree_Indices : constant Syntax_Trees.Valid_Node_Index_Array := Tree.Get_Terminals
                       (Tokens (3));
                     --   %conflict <action_a>/<action_b> in state <LHS_A>, <LHS_B> on token <on>
                     --              1        2 3         4  5      6     7  8      9  10     11
                  begin
                     Data.Conflicts.Append
                       ((Source_Line => Data.Terminals.all (Tree.Terminal (Tree_Indices (1))).Line,
                         Action_A    => +Get_Text (Data, Tree, Tree_Indices (1)),
                         LHS_A       => +Get_Text (Data, Tree, Tree_Indices (6)),
                         Action_B    => +Get_Text (Data, Tree, Tree_Indices (3)),
                         LHS_B       => +Get_Text (Data, Tree, Tree_Indices (8)),
                         On          => +Get_Text (Data, Tree, Tree_Indices (11))));
                  end;

               elsif Kind = "end" then
                  --  matching '%if' specified current lexer.
                  null;

               elsif Kind = "elisp_face" then
                  Data.Tokens.Faces.Append (Get_Text (Data, Tree, Tokens (3), Strip_Quotes => True));

               elsif Kind = "elisp_indent" then
                  Data.Tokens.Indents.Append
                    ((Name  => +Get_Child_Text (Data, Tree, Tokens (3), 1, Strip_Quotes => True),
                      Value => +Get_Child_Text (Data, Tree, Tokens (3), 2)));

               elsif Kind = "elisp_action" then
                  Data.Tokens.Actions.Insert
                    (Key             => +Get_Child_Text (Data, Tree, Tokens (3), 2),
                     New_Item        =>
                       (Action_Label => +Get_Child_Text (Data, Tree, Tokens (3), 1),
                        Ada_Name     => +Get_Child_Text (Data, Tree, Tokens (3), 3)));

               elsif Kind = "end_names_optional_option" then
                  Data.Language_Params.End_Names_Optional_Option := +Get_Text (Data, Tree, Tokens (3));

               elsif Kind = "generate" then
                  --  Not in Other phase
                  null;

               elsif Kind = "language_runtime" then
                  Data.Language_Params.Language_Runtime_Name :=
                    +Get_Text (Data, Tree, Tokens (3), Strip_Quotes => True);

               elsif Kind = "mckenzie_check_limit" then
                  Data.Language_Params.Error_Recover := True;
                  Data.McKenzie_Recover.Check_Limit := Token_Index'Value (Get_Text (Data, Tree, Tokens (3)));

               elsif Kind = "mckenzie_check_delta_limit" then
                  Data.Language_Params.Error_Recover := True;
                  Data.McKenzie_Recover.Check_Delta_Limit := Integer'Value (Get_Text (Data, Tree, Tokens (3)));

               elsif Kind = "mckenzie_cost_default" then
                  if Tree.Get_Terminals (Tokens (3))'Length /= 4 then
                     raise Grammar_Error with
                       Error_Message
                         (Data.Grammar_Lexer.File_Name, Data.Terminals.all (Tree.Min_Terminal_Index (Tokens (3))).Line,
                          "too " & (if Tree.Get_Terminals (Tokens (3))'Length > 4 then "many" else "few") &
                            " default costs; should be 'insert, delete, push back, ignore check fail'.");
                  end if;

                  Data.Language_Params.Error_Recover := True;
                  Data.McKenzie_Recover.Source_Line := Data.Terminals.all (Tree.Min_Terminal_Index (Tokens (1))).Line;

                  Data.McKenzie_Recover.Default_Insert          := Natural'Value
                    (Get_Child_Text (Data, Tree, Tokens (3), 1));
                  Data.McKenzie_Recover.Default_Delete_Terminal := Natural'Value
                    (Get_Child_Text (Data, Tree, Tokens (3), 2));
                  Data.McKenzie_Recover.Default_Push_Back       := Natural'Value
                    (Get_Child_Text (Data, Tree, Tokens (3), 3));
                  Data.McKenzie_Recover.Ignore_Check_Fail       := Natural'Value
                    (Get_Child_Text (Data, Tree, Tokens (3), 4));

               elsif Kind = "mckenzie_cost_delete" then
                  Data.Language_Params.Error_Recover := True;
                  Data.McKenzie_Recover.Delete.Append
                    ((+Get_Child_Text (Data, Tree, Tokens (3), 1),
                      +Get_Child_Text (Data, Tree, Tokens (3), 2)));

               elsif Kind = "mckenzie_cost_fast_forward" then
                  Data.Language_Params.Error_Recover := True;
                  Data.McKenzie_Recover.Fast_Forward :=
                    Integer'Value (Get_Text (Data, Tree, Tokens (3)));

               elsif Kind = "mckenzie_cost_insert" then
                  Data.Language_Params.Error_Recover := True;
                  Data.McKenzie_Recover.Insert.Append
                    ((+Get_Child_Text (Data, Tree, Tokens (3), 1),
                      +Get_Child_Text (Data, Tree, Tokens (3), 2)));

               elsif Kind = "mckenzie_cost_matching_begin" then
                  Data.Language_Params.Error_Recover := True;
                  Data.McKenzie_Recover.Matching_Begin :=
                    Integer'Value (Get_Text (Data, Tree, Tokens (3)));

               elsif Kind = "mckenzie_cost_push_back" then
                  Data.Language_Params.Error_Recover := True;
                  Data.McKenzie_Recover.Push_Back.Append
                    ((+Get_Child_Text (Data, Tree, Tokens (3), 1),
                      +Get_Child_Text (Data, Tree, Tokens (3), 2)));

               elsif Kind = "mckenzie_cost_undo_reduce" then
                  Data.Language_Params.Error_Recover := True;
                  Data.McKenzie_Recover.Undo_Reduce.Append
                    ((+Get_Child_Text (Data, Tree, Tokens (3), 1),
                      +Get_Child_Text (Data, Tree, Tokens (3), 2)));

               elsif Kind = "mckenzie_enqueue_limit" then
                  Data.Language_Params.Error_Recover := True;
                  Data.McKenzie_Recover.Enqueue_Limit := Natural'Value (Get_Text (Data, Tree, Tokens (3)));

               elsif Kind = "mckenzie_minimal_complete_cost_delta" then
                  Data.Language_Params.Error_Recover := True;
                  Data.McKenzie_Recover.Minimal_Complete_Cost_Delta :=
                    Integer'Value (Get_Text (Data, Tree, Tokens (3)));

               elsif Kind = "meta_syntax" then
                  --  not in Other phase
                  null;

               elsif Kind = "no_enum" then
                  Data.Language_Params.Declare_Enums := False;

               elsif Kind = "no_language_runtime" then
                  Data.Language_Params.Use_Language_Runtime := False;

               elsif Kind = "partial_recursion" then
                  Data.Language_Params.Partial_Recursion := True;

               elsif Kind = "start" then
                  Data.Language_Params.Start_Token := +Get_Text (Data, Tree, Tokens (3));

               elsif Kind = "re2c_regexp" then
                  Data.Tokens.re2c_Regexps.Append
                    ((+Get_Child_Text (Data, Tree, Tokens (3), 1),
                      +Get_Child_Text (Data, Tree, Tokens (3), 2)));

               else
                  raise Grammar_Error with Error_Message
                    (Data.Grammar_Lexer.File_Name, Token (2).Line, Token (2).Column, "unexpected syntax");

               end if;
            end;

         when others =>
            raise Grammar_Error with Error_Message
              (Data.Grammar_Lexer.File_Name, Token (2).Line, Token (2).Column, "unexpected syntax");
         end case;

      when Syntax_Trees.Virtual_Terminal | Syntax_Trees.Virtual_Identifier =>
         raise SAL.Programmer_Error;
      end case;
   end Add_Declaration;

   procedure Add_Nonterminal
     (User_Data : in out WisiToken.Syntax_Trees.User_Data_Type'Class;
      Tree      : in     WisiToken.Syntax_Trees.Tree;
      Tokens    : in     WisiToken.Syntax_Trees.Valid_Node_Index_Array)
   is
      use all type Ada.Containers.Count_Type;
      use WisiToken.Syntax_Trees;

      Data : User_Data_Type renames User_Data_Type (User_Data);

      LHS_Node   : constant Valid_Node_Index := Tokens (1);
      LHS_String : constant String           := Get_Text (Data, Tree, LHS_Node);

      Right_Hand_Sides : WisiToken.BNF.RHS_Lists.List;
      Labels           : WisiToken.BNF.String_Arrays.Vector;
   begin
      if Data.Phase = Meta or Data.Ignore_Lines then
         return;
      end if;

      Data.Rule_Count := Data.Rule_Count + 1;

      Get_Right_Hand_Sides (Data, Tree, Right_Hand_Sides, Labels, Tokens (3));

      if WisiToken.BNF.Is_Present (Data.Tokens.Rules, LHS_String) then
         case Tree.Label (LHS_Node) is
         when Shared_Terminal =>
            declare
               LHS_Token : Base_Token renames Data.Terminals.all (Tree.Terminal (LHS_Node));
            begin
               raise Grammar_Error with Error_Message
                 (Data.Grammar_Lexer.File_Name, LHS_Token.Line, LHS_Token.Column, "duplicate nonterm");
            end;

         when Virtual_Identifier =>
            raise Grammar_Error with Error_Message
              (Data.Grammar_Lexer.File_Name, 1, 1, "duplicate virtual nonterm '" & LHS_String & "'");

         when others =>
            Raise_Programmer_Error ("Add_Nonterminal", Tree, LHS_Node);
         end case;
      else
         Data.Label_Count := Data.Label_Count + Labels.Length;

         Data.Tokens.Rules.Append
           ((+LHS_String, Right_Hand_Sides, Labels,
             Source_Line =>
               (case Tree.Label (LHS_Node) is
                when Shared_Terminal    => Data.Terminals.all (Tree.Min_Terminal_Index (LHS_Node)).Line,
                when Virtual_Identifier => Invalid_Line_Number, -- IMPROVEME: get line from Right_Hand_Sides
                when others             => raise SAL.Programmer_Error)));
      end if;
   end Add_Nonterminal;

   procedure Check_EBNF
     (User_Data : in out WisiToken.Syntax_Trees.User_Data_Type'Class;
      Tree      : in     WisiToken.Syntax_Trees.Tree;
      Tokens    : in     WisiToken.Syntax_Trees.Valid_Node_Index_Array;
      Token     : in     WisiToken.Positive_Index_Type)
   is
      Data : User_Data_Type renames User_Data_Type (User_Data);
   begin
      case Data.Phase is
      when Meta =>
         Data.EBNF_Nodes (Tokens (Token)) := True;

         if Data.Meta_Syntax /= EBNF_Syntax then
            declare
               Tok  : Base_Token renames Data.Terminals.all (Tree.Min_Terminal_Index (Tokens (Token)));
            begin
               raise Grammar_Error with Error_Message
                 (Data.Grammar_Lexer.File_Name, Tok.Line, Tok.Column,
                  "EBNF syntax used, but BNF specified; set '%meta_syntax EBNF'");
            end;
         end if;
      when Other =>
         Raise_Programmer_Error ("untranslated EBNF node", Tree, Tree.Parent (Tokens (Token)));
      end case;
   end Check_EBNF;

   procedure Translate_EBNF_To_BNF
     (Tree : in out WisiToken.Syntax_Trees.Tree;
      Data : in out User_Data_Type)
   is
      use WisiToken.Syntax_Trees;

      Copied_EBNF_Nodes : WisiToken.Syntax_Trees.Valid_Node_Index_Arrays.Vector;

      Symbol_Regexp : constant GNAT.Regexp.Regexp := GNAT.Regexp.Compile
        ((if Data.Language_Params.Case_Insensitive
          then "[A-Z0-9_]+"
          else "[a-zA-Z0-9_]+"),
         Case_Sensitive => not Data.Language_Params.Case_Insensitive);

      procedure Clear_EBNF_Node (Node : in Valid_Node_Index)
      is begin
         if Node in Data.EBNF_Nodes.First_Index .. Data.EBNF_Nodes.Last_Index then
            Data.EBNF_Nodes (Node) := False;
            --  else in Copied_EBNF_Nodes; don't need to delete from there.
         end if;
      end Clear_EBNF_Node;

      function New_Identifier (Text : in String) return Identifier_Index
      is
         ID : constant Identifier_Index := Base_Identifier_Index (Data.Tokens.Virtual_Identifiers.Length) + 1;
      begin
         Data.Tokens.Virtual_Identifiers.Append (+Text);
         return ID;
      end New_Identifier;

      Keyword_Ident : constant Identifier_Index := New_Identifier ("keyword");
      Percent_Ident : constant Identifier_Index := New_Identifier ("percent");

      function Next_Nonterm_Name (Suffix : in String := "") return Identifier_Index
      is
         function Image is new SAL.Generic_Decimal_Image (Identifier_Index);
         ID : constant Identifier_Index := Identifier_Index (Data.Tokens.Virtual_Identifiers.Length) + 1;
      begin

         if ID > 999 then
            --  We assume 3 digits below
            raise SAL.Programmer_Error with "more than 3 digits needed for virtual identifiers in EBNF translate";
         end if;

         Data.Tokens.Virtual_Identifiers.Append (+("nonterminal_" & Image (ID, Width => 3) & Suffix));

         return ID;
      end Next_Nonterm_Name;

      function Tree_Add_Nonterminal
        (Child_1 : in Valid_Node_Index;
         Child_2 : in Valid_Node_Index;
         Child_3 : in Valid_Node_Index;
         Child_4 : in Valid_Node_Index)
        return Valid_Node_Index
      is begin
         --  Work around GNAT error about arbitrary evaluation order in
         --  aggregates (no error about the arbitrary order in subprogram
         --  parameter_assocation_lists!).
         return Tree.Add_Nonterm
           (Production => (+nonterminal_ID, 0),
            Children   => (Child_1, Child_2, Child_3, Child_4),
            Action     => Wisitoken_Grammar_Actions.nonterminal_0'Access);
      end Tree_Add_Nonterminal;

      function List_Root (Item : in Valid_Node_Index) return Valid_Node_Index
      is
         List_ID : constant WisiToken.Token_ID := Tree.ID (Item);
         Node : Valid_Node_Index := Item;
      begin
         loop
            exit when Tree.ID (Tree.Parent (Node)) /= List_ID;
            Node := Tree.Parent (Node);
         end loop;
         return Node;
      end List_Root;

      function List_Singleton (Root : in Valid_Node_Index) return Boolean
      is begin
         return Tree.RHS_Index (Root) = 0;
      end List_Singleton;

      function First_List_Element (Root : in Valid_Node_Index; Element_ID : in WisiToken.Token_ID) return Node_Index
      is
         List_ID : constant WisiToken.Token_ID := Tree.ID (Root);

         --  Return the first child with Element_ID in list of List_IDs. This
         --  is not the same as Find_Descendant, because we check the children
         --  first, and only the first child.
         Node : Node_Index := Root;
      begin
         loop
            declare
               Children : constant Valid_Node_Index_Array := Tree.Children (Node);
            begin
               if Tree.ID (Children (1)) = List_ID then
                  Node := Children (1);
               elsif Tree.ID (Children (1)) = Element_ID then
                  Node := Children (1);
                  exit;
               else
                  Raise_Programmer_Error ("first_list_element", Tree, Node);
               end if;
            end;
         end loop;
         return Node;
      end First_List_Element;

      function Last_List_Element (Root : in Valid_Node_Index) return Node_Index
      is
         --  Tree is one of:
         --
         --  case a: single element list
         --  element_list : root
         --  | element: Last
         --
         --  case c: no next
         --  element_list: root
         --  | element_list
         --  | | element:
         --  | element: Last
         Children : constant Valid_Node_Index_Array := Tree.Children (Root);
      begin
         return Children (Children'Last);
      end Last_List_Element;

      function Next_List_Element
        (Element : in Valid_Node_Index;
         List_ID : in WisiToken.Token_ID)
        return Node_Index
      with Pre => Tree.Parent (Element, 2) /= Invalid_Node_Index and then
                  Tree.ID (Tree.Parent (Element)) = List_ID
      is
         use all type SAL.Base_Peek_Type;
         --  Tree is one of:
         --
         --  case a: first element, no next
         --  rhs
         --  | rhs_item_list
         --  | | rhs_item: Element
         --  | action
         --
         --  case b: first element, next
         --  rhs_item_list
         --  | rhs_item_list
         --  | | rhs_item: Element
         --  | rhs_item: next element
         --
         --  case c: non-first element, no next
         --  rhs
         --  | rhs_item_list
         --  | | rhs_item_list
         --  | | | rhs_item:
         --  | | rhs_item: Element
         --  | action
         --
         --  case d: non-first element, next
         --  rhs_item_list
         --  | rhs_item_list
         --  | | rhs_item_list
         --  | | | rhs_item:
         --  | | rhs_item: Element
         --  | rhs_item: next element

         Element_ID      : constant WisiToken.Token_ID     := Tree.ID (Element);
         Grand_Parent    : constant Valid_Node_Index       := Tree.Parent (Element, 2);
         Aunts           : constant Valid_Node_Index_Array := Tree.Children (Grand_Parent);
         Last_List_Child : SAL.Base_Peek_Type              := Aunts'First - 1;
      begin
         if Tree.ID (Grand_Parent) /= List_ID then
            --  No next
            return Invalid_Node_Index;
         end if;

         --  Children may be non-list items; ACTION in an rhs_list, for example.
         for I in Aunts'Range loop
            if Tree.ID (Aunts (I)) in List_ID | Element_ID then
               Last_List_Child := I;
            end if;
         end loop;

         if Last_List_Child = 1 then
            --  No next
            return Invalid_Node_Index;
         else
            return Aunts (2);
         end if;
      end Next_List_Element;

      function Prev_List_Element
        (Element : in Valid_Node_Index;
         List_ID : in WisiToken.Token_ID)
        return Node_Index
      with Pre => Tree.Parent (Element) /= Invalid_Node_Index and then
                  Tree.ID (Tree.Parent (Element)) = List_ID
      is
         --  Tree is one of:
         --
         --  case a: first element, no prev
         --  ?
         --  | rhs_item_list
         --  | | rhs_item: Element
         --
         --  case b: second element
         --  ?
         --  | rhs_item_list
         --  | | rhs_item: prev item
         --  | rhs_item: Element
         --
         --  case c: nth element
         --  ?
         --  | rhs_item_list
         --  | | rhs_item_list
         --  | | | rhs_item:
         --  | | rhs_item: prev element
         --  | rhs_item: Element

         Parent : constant Valid_Node_Index := Tree.Parent (Element);
      begin
         if Element = Tree.Child (Parent, 1) then
            --  No prev
            return Invalid_Node_Index;

         else
            declare
               Prev_Children : constant Valid_Node_Index_Array := Tree.Children (Tree.Child (Parent, 1));
            begin
               return Prev_Children (Prev_Children'Last);
            end;
         end if;
      end Prev_List_Element;

      procedure Append_Element
        (Tail_List    : in Valid_Node_Index;
         New_Element  : in Valid_Node_Index;
         Separator_ID : in WisiToken.Token_ID := Invalid_Token_ID)
      is
         --  Tail_List is preserved.

         --  Current tree is one of:
         --
         --  case a:
         --  rhs_list: Tail_List
         --  | rhs: Orig_Element_1
         --
         --  case b:
         --  rhs_list: Tail_List
         --  | rhs_list: Orig_List_1
         --  | | rhs: Orig_Element_1
         --  | BAR
         --  | rhs: Orig_Element_2

         --  New tree:
         --
         --  case a:
         --  rhs_list: keep Tail_List
         --  | rhs_list: new
         --  | | rhs: keep; Orig_Element_1
         --  | BAR
         --  | rhs: New_Element
         --
         --  case b:
         --  rhs_list: keep Tail_List
         --  | rhs_list: new;
         --  | | rhs_list: keep Orig_List_1
         --  | | | rhs: keep Orig_Element_1
         --  | | BAR: keep
         --  | | rhs: keep Orig_Element_2
         --  | BAR: new
         --  | rhs: New_Element

         List_ID       : constant WisiToken.Token_ID     := Tree.ID (Tail_List);
         Children      : constant Valid_Node_Index_Array := Tree.Children (Tail_List);
         New_List_Item : constant Valid_Node_Index       := Tree.Add_Nonterm
           ((List_ID, (if Children'Length = 1 then 0 else 1)), Children);
      begin
         if Separator_ID = Invalid_Token_ID then
            Tree.Set_Children (Tail_List, (List_ID, 1), (New_List_Item, New_Element));
         else
            Tree.Set_Children
              (Tail_List, (List_ID, 1), (New_List_Item, Tree.Add_Terminal (Separator_ID), New_Element));
         end if;
      end Append_Element;

      procedure Insert_Optional_RHS (B : in Valid_Node_Index)
      is
         --  B is an optional item in an rhs_item_list :
         --  | a b? c
         --
         --  Insert a second rhs_item_list without B
         --
         --  The containing elment may be rhs or rhs_alternative_list

         Container                 : constant Valid_Node_Index := Tree.Find_Ancestor
           (B, (+rhs_ID, +rhs_alternative_list_ID));
         Orig_RHS_Element_C_Head   : constant Node_Index       := Next_List_Element
           (Tree.Parent (B, 2), +rhs_item_list_ID);
         Orig_RHS_Item_List_C_Root : constant Valid_Node_Index := List_Root (Tree.Parent (B, 3));
         Orig_RHS_Item_List_A_Root : constant Valid_Node_Index := Tree.Child (Tree.Parent (B, 3), 1);
         Orig_RHS_Element_A_Head   : constant Node_Index       :=
           (if Orig_RHS_Item_List_A_Root = Tree.Parent (B, 2)
            then Invalid_Node_Index -- a is empty
            else First_List_Element (Orig_RHS_Item_List_A_Root, +rhs_element_ID));
         Container_List            : constant Valid_Node_Index :=
           (if Tree.ID (Container) = +rhs_ID then Tree.Parent (Container) else Container);
         New_RHS_Item_List_A       : Node_Index                := Invalid_Node_Index;
         New_RHS_Item_List_C       : Node_Index                := Invalid_Node_Index;
         New_RHS_AC                : Valid_Node_Index;

         function Add_Actions (RHS_Item_List : Valid_Node_Index) return Valid_Node_Index
         with Pre => Tree.ID (Container) = +rhs_ID
         is
            Orig_RHS_Children : constant Valid_Node_Index_Array := Tree.Children (Container);
         begin
            case Tree.RHS_Index (Container) is
            when 1 =>
               return Tree.Add_Nonterm ((+rhs_ID, 1), (1 => RHS_Item_List));

            when 2   =>
               return Tree.Add_Nonterm
                 ((+rhs_ID, 2),
                  (1 => RHS_Item_List,
                   2 => Tree.Add_Terminal
                     (Tree.Min_Terminal_Index (Orig_RHS_Children (2)),
                      Data.Terminals.all)));

            when 3   =>
               return Tree.Add_Nonterm
                 ((+rhs_ID, 3),
                  (1 => RHS_Item_List,
                   2 => Tree.Add_Terminal
                     (Tree.Min_Terminal_Index (Orig_RHS_Children (2)),
                      Data.Terminals.all),
                   3 => Tree.Add_Terminal
                     (Tree.Min_Terminal_Index (Orig_RHS_Children (3)),
                      Data.Terminals.all)));

            when others =>
               Raise_Programmer_Error
                 ("translate_ebnf_to_bnf insert_optional_rhs unimplemented RHS", Tree, Container);
            end case;
         end Add_Actions;
      begin
         if Orig_RHS_Element_A_Head /= Invalid_Node_Index then
            --  a is not empty
            New_RHS_Item_List_A := Tree.Copy_Subtree
              (Last => Orig_RHS_Element_A_Head,
               Root => Orig_RHS_Item_List_A_Root);

            if Trace_Generate > Extra then
               Ada.Text_IO.New_Line;
               Ada.Text_IO.Put_Line ("new a:");
               Tree.Print_Tree (Wisitoken_Grammar_Actions.Descriptor, New_RHS_Item_List_A);
            end if;
         end if;

         if Orig_RHS_Element_C_Head /= Invalid_Node_Index then
            --  c is not empty
            New_RHS_Item_List_C := Tree.Copy_Subtree
              (Last => Orig_RHS_Element_C_Head,
               Root => Orig_RHS_Item_List_C_Root);

            if Trace_Generate > Extra then
               Ada.Text_IO.New_Line;
               Ada.Text_IO.Put_Line ("new c:");
               Tree.Print_Tree (Wisitoken_Grammar_Actions.Descriptor, New_RHS_Item_List_C);
            end if;
         end if;

         if New_RHS_Item_List_C = Invalid_Node_Index then
            if New_RHS_Item_List_A = Invalid_Node_Index then
               --  a c is empty; there cannot be any actions.
               New_RHS_AC :=
                 (if Tree.ID (Container) = +rhs_ID
                  then Tree.Add_Nonterm ((+rhs_ID, 0), (1 .. 0 => Invalid_Node_Index))
                  else Tree.Add_Nonterm ((+rhs_item_list_ID, 0), (1 .. 0 => Invalid_Node_Index)));
            else
               --  c is empty
               New_RHS_AC :=
                 (if Tree.ID (Container) = +rhs_ID
                  then Add_Actions (New_RHS_Item_List_A)
                  else New_RHS_Item_List_A);
            end if;
         else
            --  c is not empty
            if New_RHS_Item_List_A = Invalid_Node_Index then
               --  a is empty
               New_RHS_AC :=
                 (if Tree.ID (Container) = +rhs_ID
                  then Add_Actions (New_RHS_Item_List_C)
                  else New_RHS_Item_List_C);
            else
               declare
                  Tail_Element_A : constant Valid_Node_Index := Last_List_Element (New_RHS_Item_List_A);
                  Head_Element_B : constant Valid_Node_Index := First_List_Element
                    (New_RHS_Item_List_C, +rhs_element_ID);
               begin
                  Tree.Set_Children
                    (Tree.Parent (Head_Element_B),
                     (+rhs_item_list_ID, 1),
                     (Tree.Parent (Tail_Element_A), Head_Element_B));
               end;

               New_RHS_AC :=
                 (if Tree.ID (Container) = +rhs_ID
                  then Add_Actions (New_RHS_Item_List_C)
                  else New_RHS_Item_List_C);
            end if;
         end if;

         if Trace_Generate > Extra then
            Ada.Text_IO.New_Line;
            Ada.Text_IO.Put_Line ("new ac:");
            Tree.Print_Tree (Wisitoken_Grammar_Actions.Descriptor, New_RHS_AC);
         end if;

         --  Record copied EBNF nodes
         declare
            procedure Record_Copied_Node
              (Tree : in out WisiToken.Syntax_Trees.Tree;
               Node : in WisiToken.Syntax_Trees.Valid_Node_Index)
            is begin
               if To_Token_Enum (Tree.ID (Node)) in
                 rhs_optional_item_ID |
                 rhs_multiple_item_ID |
                 rhs_group_item_ID |
                 rhs_attribute_ID |
                 STRING_LITERAL_2_ID
               then
                  Copied_EBNF_Nodes.Append (Node);
               end if;
            end Record_Copied_Node;
         begin
            Tree.Process_Tree (Record_Copied_Node'Access, New_RHS_AC);
         end;

         Append_Element (Container_List, New_RHS_AC, +BAR_ID);
      end Insert_Optional_RHS;

      Compilation_Unit_List_Tail : constant Valid_Node_Index := Tree.Child (Tree.Root, 1);

      procedure Add_Compilation_Unit (Unit : in Valid_Node_Index; Prepend : in Boolean := False)
      is
         Comp_Unit : constant Valid_Node_Index := Tree.Add_Nonterm
           ((+compilation_unit_ID, (if Tree.ID (Unit) = +declaration_ID then 0 else 1)),
            (1 => Unit));
      begin
         if Prepend then
            Append_Element
              (Tree.Parent (First_List_Element (Compilation_Unit_List_Tail, +compilation_unit_ID)), Comp_Unit);
         else
            Append_Element (Compilation_Unit_List_Tail, Comp_Unit);
         end if;

         if Trace_Generate > Extra then
            Ada.Text_IO.New_Line;
            Ada.Text_IO.Put_Line ("new comp_unit:");
            Tree.Print_Tree (Wisitoken_Grammar_Actions.Descriptor, Unit);
         end if;
      end Add_Compilation_Unit;

      function To_RHS_List (RHS_Element : in Valid_Node_Index) return Valid_Node_Index
      with Pre => Tree.ID (RHS_Element) = +rhs_element_ID
      is
         RHS_Item_List : constant Valid_Node_Index := Tree.Add_Nonterm ((+rhs_item_list_ID, 0), (1 => RHS_Element));
         RHS           : constant Valid_Node_Index := Tree.Add_Nonterm ((+rhs_ID, 1),           (1 => RHS_Item_List));
      begin
         return Tree.Add_Nonterm ((+rhs_list_ID, 0), (1 => RHS));
      end To_RHS_List;

      function Convert_RHS_Alternative (Content : in Valid_Node_Index) return Valid_Node_Index
      is
         --  Convert rhs_alternative_list rooted at Content to an rhs_list
         Node : Valid_Node_Index := Content;
      begin
         loop
            exit when Tree.RHS_Index (Node) = 0;

            --  current tree:
            --  rhs_alternative_list : Node
            --  | rhs_alternative_list: Node.Child (1)
            --  | |  ...
            --  | BAR: Node.child (2)
            --  | rhs_item_list: Node.Child (3)

            --  new tree:
            --  rhs_list: Node
            --  | rhs_alternative_list: keep Node.Child (1)
            --  | |  ...
            --  | BAR: keep
            --  | rhs: new
            --  | | rhs_item_list: keep Node,Child (3)

            Tree.Set_Children
              (Node,
               (+rhs_list_ID, 1),
               (1 => Tree.Child (Node, 1),
                2 => Tree.Child (Node, 2),
                3 => Tree.Add_Nonterm
                  ((+rhs_ID, 1),
                   (1 => Tree.Child (Node, 3)))));

            Clear_EBNF_Node (Node);
            Node := Tree.Child (Node, 1);
         end loop;

         --  current tree:
         --  rhs_alternative_list : Node
         --  | rhs_item_list: Node.Child (1)

         --  new tree:
         --  rhs_list: Node
         --  | rhs: new
         --  | | rhs_item_list: Node.Child (1)

         Tree.Set_Children
           (Node,
            (+rhs_list_ID, 0),
            (1 => Tree.Add_Nonterm ((+rhs_ID, 1), (1 => Tree.Child (Node, 1)))));

         Clear_EBNF_Node (Content);
         return Content;
      end Convert_RHS_Alternative;

      procedure New_Nonterminal
        (New_Identifier : in Identifier_Index;
         Content        : in Valid_Node_Index)
         with Pre => To_Token_Enum (Tree.ID (Content)) in rhs_alternative_list_ID | rhs_element_ID
      is
         --  Convert subtree rooted at Content to an rhs_list contained by a new nonterminal
         --  named New_Identifier.
         New_Nonterm : constant Valid_Node_Index := Tree_Add_Nonterminal
           (Child_1   => Tree.Add_Identifier (+IDENTIFIER_ID, New_Identifier, Tree.Byte_Region (Content)),
            Child_2   => Tree.Add_Terminal (+COLON_ID),
            Child_3   =>
              (case To_Token_Enum (Tree.ID (Content)) is
               when rhs_element_ID          => To_RHS_List (Content),
               when rhs_alternative_list_ID => Convert_RHS_Alternative (Content),
               when others => raise SAL.Programmer_Error with "new_nonterminal unimplemented content" &
                 Tree.Image (Content, Wisitoken_Grammar_Actions.Descriptor)),
            Child_4   => Tree.Add_Nonterm
              ((+semicolon_opt_ID, 0),
               (1     => Tree.Add_Terminal (+SEMICOLON_ID))));
      begin
         Add_Compilation_Unit (New_Nonterm);
      end New_Nonterminal;

      procedure New_Nonterminal_List_1
        (List_Nonterm  : in Identifier_Index;
         RHS_Element_1 : in Valid_Node_Index;
         RHS_Element_3 : in Valid_Node_Index;
         Byte_Region   : in Buffer_Region)
      is
         --  nonterminal: foo_list
         --  | IDENTIFIER: "foo_list" List_Nonterm
         --  | COLON:
         --  | rhs_list:
         --  | | rhs_list: RHS_List_2
         --  | | | rhs: RHS_2
         --  | | | | rhs_item_list: RHS_Item_List_1
         --  | | | | | rhs_element: RHS_Element_1
         --  | | | | | | rhs_item: RHS_Item_1
         --  | | | | | | | IDENTIFIER: List_Element
         --  | | BAR:
         --  | | rhs: RHS_3
         --  | | | rhs_item_list: RHS_Item_List_2
         --  | | | | | rhs_item_list: RHS_Item_List_3
         --  | | | | | |  rhs_element: RHS_Element_2
         --  | | | | | | | rhs_item: RHS_Item_2
         --  | | | | | | | | IDENTIFIER: List_Nonterm
         --  | | | | rhs_element: RHS_Element_3
         --  | | | | | rhs_item: RHS_Item_3
         --  | | | | | | IDENTIFIER: List_Element
         --  | semicolon_opt:
         --  | | SEMICOLON:

         RHS_Item_2 : constant Valid_Node_Index := Tree.Add_Nonterm
           ((+rhs_item_ID, 0), (1 => Tree.Add_Identifier (+IDENTIFIER_ID, List_Nonterm, Byte_Region)));

         RHS_Element_2 : constant Valid_Node_Index := Tree.Add_Nonterm ((+rhs_element_ID, 0), (1 => RHS_Item_2));

         RHS_Item_List_1 : constant Valid_Node_Index := Tree.Add_Nonterm ((+rhs_item_list_ID, 0), (1 => RHS_Element_1));
         RHS_Item_List_3 : constant Valid_Node_Index := Tree.Add_Nonterm ((+rhs_item_list_ID, 0), (1 => RHS_Element_2));
         RHS_Item_List_2 : constant Valid_Node_Index := Tree.Add_Nonterm
           ((+rhs_item_list_ID, 1), (1 => RHS_Item_List_3, 2 => RHS_Element_3));

         RHS_2 : constant Valid_Node_Index := Tree.Add_Nonterm ((+rhs_ID, 1), (1 => RHS_Item_List_1));
         RHS_3 : constant Valid_Node_Index := Tree.Add_Nonterm ((+rhs_ID, 1), (1 => RHS_Item_List_2));

         Bar_1 : constant Valid_Node_Index := Tree.Add_Terminal (+BAR_ID);

         RHS_List_2 : constant Valid_Node_Index := Tree.Add_Nonterm ((+rhs_list_ID, 0), (1 => RHS_2));

         List_Nonterminal : constant Valid_Node_Index := Tree_Add_Nonterminal
           (Child_1   => Tree.Add_Identifier (+IDENTIFIER_ID, List_Nonterm, Byte_Region),
            Child_2   => Tree.Add_Terminal (+COLON_ID),
            Child_3   => Tree.Add_Nonterm
              ((+rhs_list_ID, 1),
               (1     => RHS_List_2,
                2     => Bar_1,
                3     => RHS_3)),
            Child_4   => Tree.Add_Nonterm
              ((+semicolon_opt_ID, 0),
               (1     => Tree.Add_Terminal (+SEMICOLON_ID))));
      begin
         Add_Compilation_Unit (List_Nonterminal);
      end New_Nonterminal_List_1;

      procedure New_Nonterminal_List
        (List_Nonterm : in Identifier_Index;
         List_Element : in Identifier_Index;
         Byte_Region  : in Buffer_Region)
      is
         RHS_Item_1 : constant Valid_Node_Index := Tree.Add_Nonterm
           ((+rhs_item_ID, 0), (1 => Tree.Add_Identifier (+IDENTIFIER_ID, List_Element, Byte_Region)));
         RHS_Item_3 : constant Valid_Node_Index := Tree.Add_Nonterm
           ((+rhs_item_ID, 0), (1 => Tree.Add_Identifier (+IDENTIFIER_ID, List_Element, Byte_Region)));
         RHS_Element_1 : constant Valid_Node_Index := Tree.Add_Nonterm ((+rhs_element_ID, 0), (1 => RHS_Item_1));
         RHS_Element_3 : constant Valid_Node_Index := Tree.Add_Nonterm ((+rhs_element_ID, 0), (1 => RHS_Item_3));
      begin
         New_Nonterminal_List_1 (List_Nonterm, RHS_Element_1, RHS_Element_3, Byte_Region);
      end New_Nonterminal_List;

      procedure New_Nonterminal_List
        (List_Nonterm : in Identifier_Index;
         List_Element : in Token_Index;
         Terminals    : in Base_Token_Arrays.Vector;
         Byte_Region  : in Buffer_Region)
      is
         RHS_Item_1 : constant Valid_Node_Index := Tree.Add_Nonterm
           ((+rhs_item_ID, 0), (1 => Tree.Add_Terminal (List_Element, Terminals)));
         RHS_Item_3 : constant Valid_Node_Index := Tree.Add_Nonterm
           ((+rhs_item_ID, 0), (1 => Tree.Add_Terminal (List_Element, Terminals)));
         RHS_Element_1 : constant Valid_Node_Index := Tree.Add_Nonterm ((+rhs_element_ID, 0), (1 => RHS_Item_1));
         RHS_Element_3 : constant Valid_Node_Index := Tree.Add_Nonterm ((+rhs_element_ID, 0), (1 => RHS_Item_3));
      begin
         New_Nonterminal_List_1 (List_Nonterm, RHS_Element_1, RHS_Element_3, Byte_Region);
      end New_Nonterminal_List;

      procedure Process_Node (Node : in Valid_Node_Index)
      is begin
         if Trace_Generate > Detail then
            Ada.Text_IO.New_Line;
            Ada.Text_IO.Put_Line ("translate node" & Node_Index'Image (Node));
         end if;

         case To_Token_Enum (Tree.ID (Node)) is
         --  Token_Enum_ID alphabetical order
         when declaration_ID =>
            --  Must be "%meta_syntax EBNF"; change to BNF
            declare
               Decl_Item : constant Valid_Node_Index := Tree.Find_Descendant
                 (Tree.Child (Node, 3), +declaration_item_ID);
               Children : Valid_Node_Index_Array := Tree.Children (Decl_Item);
            begin
               Children (1) := Tree.Add_Identifier
                 (+IDENTIFIER_ID, New_Identifier ("BNF"), Tree.Byte_Region (Decl_Item));
               Tree.Set_Children (Decl_Item, (+declaration_item_ID, 1), Children);
            end;

         when rhs_alternative_list_ID =>
            --  All handled by New_Nonterminal*
            raise SAL.Not_Implemented with Tree.Image (Node, Wisitoken_Grammar_Actions.Descriptor);

         when rhs_attribute_ID =>
            --  Just delete it
            --
            --  Current tree (so far, attributes are always the first item in an rhs):
            --
            --  rhs:
            --  | ...
            --  | rhs_item_list: RHS_Item_List.Parent 2
            --  | | rhs_item_list: RHS_Item_List.Parent 1
            --  | | | rhs_item_list: RHS_Item_List
            --  | | | | rhs_element: Parent (Node, 2)
            --  | | | | | rhs_item: Parent (Node, 1)
            --  | | | | | | rhs_attribute: Node
            --  | | | rhs_element: next_element 1
            --  | | rhs_element: next_element 2
            --
            --  New tree:
            --
            --  rhs:
            --  | ...
            --  | rhs_item_list: keep RHS_Item_List.Parent
            --  | | rhs_element: keep next_element 1
            --  | rhs_element: kepp next_element 2
            declare
               RHS_Item_List : constant Valid_Node_Index   := Tree.Parent (Node, 3);
               Parent        : constant Valid_Node_Index   := Tree.Parent (RHS_Item_List);
            begin
               if Tree.RHS_Index (RHS_Item_List) /= 0 then
                  --  Not first
                  Raise_Programmer_Error ("translate_ebnf_to_bnf rhs_attribute_id unimplemented", Tree, Node);
               end if;

               Tree.Set_Children
                 (Parent,
                  (+rhs_item_list_ID, 0),
                  (1 => Tree.Child (Parent, 2)));
            end;

         when rhs_group_item_ID =>
            --  Current tree:
            --
            --  rhs_element: Parent (Node, 2)
            --  | rhs_item: Parent (Node, 1)
            --  | | rhs_group_item: Node
            --  | | | LEFT_PAREN
            --  | | | rhs_alternative_list: Child (Node, 2)
            --  | | | RIGHT_PAREN

            --  See if there's an existing nonterminal for this content.
            declare
               Element_Content : constant String       := Get_Text (Data, Tree, Tree.Child (Node, 2));
               Temp            : Node_Index            := First_List_Element
                 (Tree.Child (Tree.Root, 1), +compilation_unit_ID);
               Name_Node       : Node_Index;
               New_Ident       : Base_Identifier_Index := Invalid_Identifier_Index;
            begin
               loop
                  pragma Assert (Tree.ID (Temp) = +compilation_unit_ID);

                  if Tree.Production_ID (Tree.Child (Temp, 1)) = (+nonterminal_ID, 0) then
                     --  Target nonterm is:
                     --
                     --  (compilation_unit_1, (111 . 128))
                     --  | (nonterminal_0, (111 . 128))
                     --  | |  7;(IDENTIFIER, (111 . 128))
                     --  | | (COLON)
                     --  | | (rhs_list_1, (111 . 128))
                     --  | | | ...
                     declare
                        RHS_List_1 : constant Node_Index := Tree.Child (Tree.Child (Temp, 1), 3);
                     begin
                        if RHS_List_1 /= Invalid_Node_Index and then
                          Element_Content = Get_Text (Data, Tree, RHS_List_1)
                        then
                           Name_Node := Tree.Child (Tree.Child (Temp, 1), 1);
                           case Tree.Label (Name_Node) is
                           when Shared_Terminal =>
                              New_Ident := New_Identifier (Get_Text (Data, Tree, Name_Node));
                           when Virtual_Identifier =>
                              New_Ident := Tree.Identifier (Name_Node);
                           when others =>
                              Raise_Programmer_Error ("process_node rhs_group_item", Tree, Name_Node);
                           end case;

                           exit;
                        end if;
                     end;
                  end if;

                  Temp := Next_List_Element (Temp, +compilation_unit_list_ID);
                  exit when Temp = Invalid_Node_Index;
               end loop;

               if New_Ident = Invalid_Identifier_Index then
                  New_Ident := Next_Nonterm_Name;
                  New_Nonterminal (New_Ident, Tree.Child (Node, 2));
               end if;

               Tree.Set_Node_Identifier (Node, +IDENTIFIER_ID, New_Ident);
               Tree.Set_Children (Tree.Parent (Node), (+rhs_item_ID, 0), (1 => Node));
               Clear_EBNF_Node (Node);
            end;

         when rhs_multiple_item_ID =>
            --  We have one of:
            --
            --  | a { b }  c
            --  | a { b } - c
            --  | a ( b ) + c
            --  | a ( b ) * c
            --  | a b+ c
            --  | a b* c
            --
            --  Replace it with a new canonical list nonterminal:
            --
            --  nonterminal_nnn
            --  : b
            --  | nonterminal_nnn_list b
            --
            --  and a second RHS if it can be empty:
            --  | a c

            --  Current tree:
            --
            --  rhs_item: Parent (Node, 1)
            --  | rhs_multiple_item: Node
            --  | | LEFT_BRACE | LEFT_PAREN
            --  | | rhs_alternative_list
            --  | | | ...
            --  | | RIGHT_BRACE | RIGHT_PAREN
            --  | | [MINUS | PLUS | STAR]

            --  or:
            --
            --  rhs_item: Parent (Node, 1)
            --  | rhs_multiple_item: Node
            --  | | IDENTIFIER
            --  | | PLUS | STAR

            declare
               Done                       : Boolean                   := False;
               RHS_Index                  : constant Integer          := Tree.RHS_Index (Node);
               Plus_Minus_Star            : constant Node_Index       := Tree.Child
                 (Node, (if RHS_Index in 0 .. 3 then 4 else 2));
               Allow_Empty                : constant Boolean          := Plus_Minus_Star = Invalid_Node_Index or else
                 Tree.ID (Plus_Minus_Star) in +STAR_ID;
               Parent_RHS_Item            : constant Valid_Node_Index := Tree.Parent (Node);
               List_Nonterm_Virtual_Name  : Base_Identifier_Index     := Invalid_Identifier_Index;
               List_Nonterm_Terminal_Name : Base_Token_Index          := Invalid_Token_Index;
               List_Element               : Base_Identifier_Index     := Invalid_Identifier_Index;

               procedure Check_Canonical_List
               is
                  --  In EBNF, a canonical list with a separator looks like:
                  --
                  --  enumConstants : enumConstant (',' enumConstant)* ;
                  --
                  --  or, with no separator:
                  --
                  --  SwitchLabels : SwitchLabel {SwitchLabel} ;
                  --
                  --  The tokens may have labels.
                  --
                  --  Handling these cases specially this eliminates a conflict between
                  --  reducing to enumConstants and reducing to the introduced nonterm
                  --  list.
                  --
                  --  Alternately, the no separator case can be:
                  --
                  --  enumConstants : enumConstant+ ;
                  --
                  --  Handling this no separator case specially would not eliminate any conflicts.

                  use all type SAL.Base_Peek_Type;

                  Alt_List_Items : constant Valid_Node_Index_Array := Tree.Get_IDs (Node, +rhs_item_ID);
                  RHS_Element    : constant Valid_Node_Index       := Tree.Parent (Node, 2);
                  Element_1      : constant Node_Index             := Prev_List_Element
                    (RHS_Element, +rhs_item_list_ID);
                  RHS_2          : constant Valid_Node_Index       := Tree.Find_Ancestor
                    (Node, (+rhs_ID, +rhs_alternative_list_ID));
               begin
                  if Tree.ID (RHS_2) = +rhs_alternative_list_ID then return; end if;
                  if not (Alt_List_Items'Last in 1 .. 2) then return; end if;
                  if Element_1 = Invalid_Node_Index or else
                    Get_Text (Data, Tree, Tree.Get_IDs (Element_1, +rhs_item_ID)(1)) /=
                    Get_Text (Data, Tree, Alt_List_Items (Alt_List_Items'Last))
                  then
                     return;
                  end if;
                  if Invalid_Node_Index /= Next_List_Element (RHS_Element, +rhs_item_list_ID) then return; end if;
                  if Invalid_Node_Index /= Next_List_Element (RHS_2, +rhs_list_ID) or
                    Invalid_Node_Index /= Prev_List_Element (RHS_2, +rhs_list_ID)
                  then
                     return;
                  end if;

                  --  We have a canonical list declaration. Rewrite it to:
                  --
                  --  with separator:
                  --  rhs_list: keep
                  --  | rhs_list:
                  --  | | rhs: new, RHS_1
                  --  | | | rhs_item_list: new, RHS_Item_List_1
                  --  | | | | rhs_element: keep, Element_1
                  --  | | | | | rhs_item: keep
                  --  | | | | | | IDENTIFIER: keep; element name
                  --  | BAR: new
                  --  | rhs: keep, RHS_2
                  --  | | rhs_item_list: new, RHS_Item_List_2
                  --  | | | rhs_item_list: keep, rhs_item_list_3
                  --  | | | | rhs_item_list: keep, rhs_item_list_4
                  --  | | | | | rhs_element: new
                  --  | | | | | | rhs_item: new
                  --  | | | | | | | IDENTIFIER: new, list name
                  --  | | | | rhs_element: keep
                  --  | | | | | rhs_item: keep
                  --  | | | | | | IDENTIFIER: keep, separator
                  --  | | | rhs_element: keep, alt_list_elements (last)
                  --  | | | | rhs_item: keep
                  --  | | | | | IDENTIFIER: keep, element name
                  --
                  --  no separator:
                  --  rhs_list: keep
                  --  | rhs_list:
                  --  | | rhs: new, RHS_1
                  --  | | | rhs_item_list: new, RHS_Item_List_1
                  --  | | | | rhs_element: keep, Element_1
                  --  | | | | | rhs_item: keep
                  --  | | | | | | IDENTIFIER: keep; element name
                  --  | BAR: new
                  --  | rhs: keep, RHS_2
                  --  | | rhs_item_list: keep, rhs_item_list_3
                  --  | | | rhs_item_list: new, rhs_item_list_4
                  --  | | | | rhs_element: new
                  --  | | | | | rhs_item: new
                  --  | | | | | | IDENTIFIER: new, list name
                  --  | | | rhs_element: keep, alt_list_elements (last)
                  --  | | | | rhs_item: keep
                  --  | | | | | IDENTIFIER: keep, element name

                  declare
                     List_Name_Node   : constant Valid_Node_Index := Tree.Find_Ancestor (RHS_2, +nonterminal_ID);
                     List_Name_Tok    : constant Token_Index      := Tree.Min_Terminal_Index (List_Name_Node);
                     List_Name_Region : constant Buffer_Region    := Data.Terminals.all (List_Name_Tok).Byte_Region;
                     List_Name        : constant String           := Data.Grammar_Lexer.Buffer_Text (List_Name_Region);

                     RHS_2_Index    : constant Integer       := Tree.RHS_Index (RHS_2);
                     RHS_2_Children : Valid_Node_Index_Array := Tree.Children (RHS_2);

                     RHS_Item_List_1    : constant Valid_Node_Index := Tree.Add_Nonterm
                       ((+rhs_item_list_ID, 0), (1 => Element_1));

                     RHS_1_Action : constant Node_Index :=
                       (case RHS_2_Index is
                        when 2 | 3 => Tree.Add_Terminal
                          (Tree.Min_Terminal_Index (RHS_2_Children (2)), Data.Terminals.all),
                        when others => Invalid_Node_Index);

                     RHS_1_Check : constant Node_Index :=
                       (case RHS_2_Index is
                        when 3 => Tree.Add_Terminal
                          (Tree.Min_Terminal_Index (RHS_2_Children (3)), Data.Terminals.all),
                        when others => Invalid_Node_Index);

                     RHS_1              : constant Valid_Node_Index :=
                       (case RHS_2_Index is
                        when 1 => Tree.Add_Nonterm ((+rhs_ID, 1), (1 => RHS_Item_List_1)),
                        when 2 => Tree.Add_Nonterm ((+rhs_ID, 2), (1 => RHS_Item_List_1, 2 => RHS_1_Action)),
                        when 3 => Tree.Add_Nonterm
                          ((+rhs_ID, 3), (1 => RHS_Item_List_1, 2 => RHS_1_Action, 3 => RHS_1_Check)),
                        when others => raise SAL.Programmer_Error);

                     Bar                   : constant Valid_Node_Index := Tree.Add_Terminal (+BAR_ID);
                     RHS_Item_List_3       : constant Valid_Node_Index := Tree.Child (RHS_2, 1);
                     RHS_Item_List_4       : constant Valid_Node_Index := Tree.Child (RHS_Item_List_3, 1);
                     New_List_Name_Term    : constant Valid_Node_Index := Tree.Add_Terminal
                       (List_Name_Tok, Data.Terminals.all);
                     New_List_Name_Item    : constant Valid_Node_Index := Tree.Add_Nonterm
                       ((+rhs_item_ID, 0),
                        (1      => New_List_Name_Term));

                     New_List_Name_Label : constant Node_Index :=
                       (if Tree.RHS_Index (Element_1) = 1
                        then --  tokens have labels
                           Tree.Add_Identifier (+IDENTIFIER_ID, New_Identifier (List_Name), List_Name_Region)
                        else Invalid_Node_Index);

                     New_List_Name_Element : constant Valid_Node_Index :=
                       (if Tree.RHS_Index (Element_1) = 1
                        then --  tokens have labels
                           Tree.Add_Nonterm
                             ((+rhs_element_ID, 1),
                             (1 => New_List_Name_Label,
                              2 => Tree.Add_Terminal (+EQUAL_ID),
                              3 => New_List_Name_Item))
                        else
                           Tree.Add_Nonterm ((+rhs_element_ID, 0), (1 => New_List_Name_Item)));

                     Alt_List_Elements : constant Valid_Node_Index_Array := Tree.Get_IDs (Node, +rhs_element_ID);
                     RHS_Item_List_2   : constant Node_Index       :=
                       (if Alt_List_Elements'Last = 1
                        then Invalid_Node_Index -- no separator
                        else Tree.Add_Nonterm
                          ((+rhs_item_list_ID, 1),
                          (1 => RHS_Item_List_3,
                           2 => Alt_List_Elements (Alt_List_Elements'Last))));

                  begin
                     Tree.Set_Children (RHS_Item_List_4, (+rhs_item_list_ID, 0), (1 => New_List_Name_Element));

                     Tree.Set_Children
                       (RHS_Item_List_3,
                        (+rhs_item_list_ID, 1),
                        (1 => RHS_Item_List_4,
                         2 => Alt_List_Elements (1)));

                     RHS_2_Children (1) :=
                       (if Alt_List_Elements'Last = 1
                        then RHS_Item_List_3 -- no separator
                        else RHS_Item_List_2);
                     Tree.Set_Children (RHS_2, (+rhs_ID, Tree.RHS_Index (RHS_2)), RHS_2_Children);

                     Tree.Set_Children
                       (Tree.Parent (RHS_2),
                        (+rhs_list_ID, 1),
                        (1 => Tree.Add_Nonterm ((+rhs_list_ID, 0), (1 => RHS_1)),
                         2 => Bar,
                         3 => RHS_2));
                  end;

                  Done := True;

                  Clear_EBNF_Node (Node);

                  if Trace_Generate > Extra then
                     Ada.Text_IO.New_Line;
                     Ada.Text_IO.Put_Line ("edited rhs_list:");
                     Tree.Print_Tree (Wisitoken_Grammar_Actions.Descriptor, Tree.Parent (RHS_2));
                  end if;
               end Check_Canonical_List;

               procedure Find_List_Nonterminal_2 (Element_Content : in String)
               is
                  --  Look for a virtual pair of nonterms implementing a list of Element_Content.
                  --  If found, set List_Nonterm_Virtual_Name, List_Element
                  Temp      : Node_Index := First_List_Element (Tree.Child (Tree.Root, 1), +compilation_unit_ID);
                  Name_Node : Node_Index;
               begin
                  loop
                     pragma Assert (Tree.ID (Temp) = +compilation_unit_ID);

                     if Tree.Production_ID (Tree.Child (Temp, 1)) = (+nonterminal_ID, 0) and
                       Tree.Is_Virtual (Tree.Child (Temp, 1))
                     then
                        if Element_Content = Get_Text (Data, Tree, Tree.Child (Tree.Child (Temp, 1), 3)) then
                           Name_Node := Tree.Child (Tree.Child (Temp, 1), 1);
                           case Tree.Label (Name_Node) is
                           when Virtual_Identifier =>
                              List_Element := Tree.Identifier (Name_Node);
                           when others =>
                              Raise_Programmer_Error
                                ("unimplemented Find_List_Nonterminal_2 case '" & Element_Content & "'",
                                 Tree, Name_Node);
                           end case;

                           --  list nonterm is the next nonterminal
                           Temp := Next_List_Element (Temp, +compilation_unit_list_ID);
                           Name_Node := Tree.Child (Tree.Child (Temp, 1), 1);
                           case Tree.Label (Name_Node) is
                           when Virtual_Identifier =>
                              List_Nonterm_Virtual_Name := Tree.Identifier (Name_Node);
                           when others =>
                              raise SAL.Programmer_Error;
                           end case;
                           exit;
                        end if;
                     end if;

                     Temp := Next_List_Element (Temp, +compilation_unit_list_ID);
                     exit when Temp = Invalid_Node_Index;
                  end loop;
               end Find_List_Nonterminal_2;

               procedure Find_List_Nonterminal_1 (Element_Content : in String)
               is
                  --  Search for a nonterm (virtual or not) implementing a list for
                  --  Element_Content, which is a single rhs_element; no List_Element
                  --  Nonterminal. If found, set List_Nonterm_Virtual_Name or
                  --  List_Nonterm_Terminal_Name
                  Temp      : Node_Index := First_List_Element (Tree.Child (Tree.Root, 1), +compilation_unit_ID);
               begin
                  loop
                     pragma Assert (Tree.ID (Temp) = +compilation_unit_ID);

                     if Tree.Production_ID (Tree.Child (Temp, 1)) = (+nonterminal_ID, 0) then
                        --  Target List_Nonterm is:
                        --
                        --  nonterminal_nnn_list
                        --     : element
                        --     | nonterminal_nnn_list element
                        --
                        --  compilation_unit
                        --  | nonterminal
                        --  | | IDENTIFIER : list_nonterm
                        --  | | COLON
                        --  | | rhs_list: rhs_list_1
                        --  | | | rhs_list: rhs_list_2
                        --  | | | | rhs
                        --  | | | | | ... List_element
                        --  | | | BAR
                        --  | | | rhs: ... list_nonterm list_element
                        declare
                           Name_Node  : constant Node_Index := Tree.Child (Tree.Child (Temp, 1), 1);
                           RHS_List_1 : constant Node_Index := Tree.Child (Tree.Child (Temp, 1), 3);
                           RHS_List_2 : constant Node_Index :=
                             (if RHS_List_1 = Invalid_Node_Index
                              then Invalid_Node_Index
                              else Tree.Child (RHS_List_1, 1));
                        begin
                           if RHS_List_2 /= Invalid_Node_Index and
                             Tree.Child (RHS_List_1, 3) /= Invalid_Node_Index and -- second rhs present
                             Tree.Child (RHS_List_2, 3) = Invalid_Node_Index -- no third rhs
                           then
                              declare
                                 RHS_1 : constant String := Get_Text (Data, Tree, RHS_List_2);
                                 RHS_2 : constant String := Get_Text (Data, Tree, Tree.Child (RHS_List_1, 3));
                                 Expected_RHS_2 : constant String := Get_Text (Data, Tree, Name_Node) & " " &
                                   Element_Content;
                              begin
                                 if Element_Content = RHS_1 and RHS_2 = Expected_RHS_2 then
                                    case Tree.Label (Name_Node) is
                                    when Shared_Terminal =>
                                       List_Nonterm_Terminal_Name := Tree.Min_Terminal_Index (Name_Node);
                                    when Virtual_Identifier =>
                                       List_Nonterm_Virtual_Name := Tree.Identifier (Name_Node);
                                    when others =>
                                       Raise_Programmer_Error
                                         ("unimplemented Find_List_Nonterminal_1 case '" & Element_Content & "'",
                                          Tree, Name_Node);
                                    end case;

                                    exit;
                                 end if;
                              end;
                           end if;
                        end;
                     end if;

                     Temp := Next_List_Element (Temp, +compilation_unit_list_ID);
                     exit when Temp = Invalid_Node_Index;
                  end loop;
               end Find_List_Nonterminal_1;
            begin
               --  Check if this is a recognized pattern
               Check_Canonical_List;
               if Done then return; end if;

               --  Check to see if there is an already declared nonterminal
               --  list with the same content; if not, create one.
               case Tree.RHS_Index (Node) is
               when 0 .. 3 =>
                  --  { rhs_alternative_list } -?
                  --  ( rhs_alternative_list ) [+*]
                  if 0 = Tree.RHS_Index (Tree.Child (Node, 2)) and then
                    0 = Tree.RHS_Index (Tree.Child (Tree.Child (Node, 2), 1))
                  then
                     --  Only one element in the rhs_alternative_list, and in the rhs_item_list
                     Find_List_Nonterminal_1 (Get_Text (Data, Tree, Tree.Child (Node, 2)));

                     if List_Nonterm_Virtual_Name = Invalid_Identifier_Index and
                       List_Nonterm_Terminal_Name = Invalid_Token_Index
                     then
                        List_Nonterm_Virtual_Name := Next_Nonterm_Name ("_list");
                        New_Nonterminal_List
                          (List_Nonterm_Virtual_Name, Tree.Min_Terminal_Index (Tree.Child (Node, 2)),
                           Data.Terminals.all, Tree.Byte_Region (Node));
                     end if;
                  else
                     Find_List_Nonterminal_2 (Get_Text (Data, Tree, Tree.Child (Node, 2)));

                     if List_Nonterm_Virtual_Name = Invalid_Identifier_Index then
                        List_Nonterm_Virtual_Name := Next_Nonterm_Name ("_list");
                        List_Element              := Next_Nonterm_Name;
                        New_Nonterminal (List_Element, Tree.Child (Node, 2));
                        New_Nonterminal_List (List_Nonterm_Virtual_Name, List_Element, Tree.Byte_Region (Node));
                     end if;
                  end if;

               when 4 | 5 =>
                  --  IDENTIFIER + | *
                  Find_List_Nonterminal_1 (Get_Text (Data, Tree, Tree.Child (Node, 1)));

                  if List_Nonterm_Virtual_Name = Invalid_Identifier_Index then
                     List_Nonterm_Virtual_Name := Next_Nonterm_Name ("_list");
                     New_Nonterminal_List
                       (List_Nonterm_Virtual_Name, Tree.Min_Terminal_Index (Tree.Child (Node, 1)), Data.Terminals.all,
                        Tree.Byte_Region (Node));
                  end if;

               when others =>
                  Raise_Programmer_Error ("translate_ebnf_to_bnf rhs_multiple_item unimplmented", Tree, Node);
               end case;

               if Allow_Empty then
                  Insert_Optional_RHS (Node);
               end if;

               declare
                  Child : constant Valid_Node_Index :=
                    (if List_Nonterm_Virtual_Name /= Invalid_Identifier_Index
                     then Tree.Add_Identifier
                       (+IDENTIFIER_ID, List_Nonterm_Virtual_Name, Tree.Byte_Region (Parent_RHS_Item))
                     elsif List_Nonterm_Terminal_Name /= Invalid_Token_Index
                     then Tree.Add_Terminal (List_Nonterm_Terminal_Name, Data.Terminals.all)
                     else raise SAL.Programmer_Error);
               begin
                  Tree.Set_Children (Parent_RHS_Item, (+rhs_item_ID, 0), (1 => Child));
               end;

               Clear_EBNF_Node (Node);

               if Trace_Generate > Extra then
                  Ada.Text_IO.New_Line;
                  Ada.Text_IO.Put_Line ("edited rhs_item:");
                  Tree.Print_Tree (Wisitoken_Grammar_Actions.Descriptor, Parent_RHS_Item);
               end if;
            exception
            when E : System.Assertions.Assert_Failure =>
               Raise_Programmer_Error
                 ("translate_ebnf_to_bnf multiple_item assert: " & Ada.Exceptions.Exception_Message (E), Tree, Node);
            end;

         when rhs_optional_item_ID =>
            --  Source looks like:
            --
            --  | a [b] c
            --
            --  where 'a', 'b', 'c' are token sequences. Translate to:
            --
            --  | a nonterm_b c
            --  | a c
            --
            --  where 'nonterm_b' is a new nonterminal containing b, unless b is
            --  simple enough to inline.
            --
            --  See nested_ebnf_optional.wy for an example of nested optional
            --  items.
            --
            --  current tree:
            --
            --  | rhs_list:
            --  | | rhs | rhs_alternative_list:
            --  | | | rhs_item_list
            --  | | | | rhs_item_list
            --  | | | ...
            --  | | | | | | rhs_element:
            --  | | | | | | | rhs_item: contains a tail
            --  | | | | | rhs_element:
            --  | | | | | | rhs_item: contains b
            --  | | | | | | | rhs_optional_item: Node
            --  | | | | | | | | LEFT_BRACKET: Node.Children (1)
            --  | | | | | | | | rhs_alternative_item_list: Node.Children (2) b
            --  | | | | | | | | RIGHT_BRACKET: Node.Children (3)
            --  | | | | rhs_element: head of c
            --  | | | | | rhs_item: head of c

            declare
               Name_Ident    : Base_Identifier_Index := Invalid_Identifier_Index;
               Name_Terminal : Base_Token_Index      := Invalid_Token_Index;
               Name_Label    : Base_Token_Index      := Invalid_Token_Index;
               Found         : Boolean               := False;
            begin
               case Tree.RHS_Index (Node) is
               when 0 | 1 =>
                  --  : LEFT_BRACKET rhs_alternative_list RIGHT_BRACKET
                  --  | LEFT_PAREN rhs_alternative_list RIGHT_PAREN QUESTION

                  --  Check for special cases

                  if List_Singleton (Tree.Child (Node, 2)) then
                     if List_Singleton (Tree.Child (Tree.Child (Node, 2), 1)) then
                        --  Single item in rhs_alternative_list and rhs_item_list; just use it.
                        --
                        --  Single alternative, multiple rhs_items handled below
                        declare
                           Name_Element_Node    : Valid_Node_Index;
                           Name_Identifier_Node : Node_Index;
                        begin
                           Found     := True;
                           Name_Element_Node := First_List_Element
                             (Tree.Child (Tree.Child (Node, 2), 1), +rhs_element_ID);

                           if Tree.RHS_Index (Name_Element_Node) = 0 then
                              Name_Identifier_Node := Tree.Child (Tree.Child (Name_Element_Node, 1), 1);
                           else
                              --  Name has a label
                              Name_Label           := Tree.Min_Terminal_Index (Tree.Child (Name_Element_Node, 1));
                              Name_Identifier_Node := Tree.Child (Tree.Child (Name_Element_Node, 3), 1);
                           end if;

                           case Tree.Label (Name_Identifier_Node) is
                           when Virtual_Identifier =>
                              Name_Ident := Tree.Identifier (Name_Identifier_Node);
                           when Shared_Terminal =>
                              Name_Terminal := Tree.Min_Terminal_Index (Name_Identifier_Node);
                           when others =>
                              Raise_Programmer_Error ("unhandled rhs_optional case ", Tree, Name_Identifier_Node);
                           end case;
                        end;
                     end if;
                  else
                     --  See if we've already created a nonterminal for this.
                     declare
                        New_Text             : constant String := Get_Text (Data, Tree, Tree.Child (Node, 2));
                        Temp                 : Node_Index      := First_List_Element
                          (Tree.Child (Tree.Root, 1), +compilation_unit_ID);
                        Name_Identifier_Node : Node_Index;
                     begin
                        loop
                           pragma Assert (Tree.ID (Temp) = +compilation_unit_ID);

                           if Tree.Production_ID (Tree.Child (Temp, 1)) = (+nonterminal_ID, 0) then
                              if New_Text = Get_Text (Data, Tree, Tree.Child (Tree.Child (Temp, 1), 3)) then
                                 Found := True;
                                 Name_Identifier_Node := Tree.Child (Tree.Child (Temp, 1), 1);
                                 case Tree.Label (Name_Identifier_Node) is
                                 when Virtual_Identifier =>
                                    Name_Ident := Tree.Identifier (Name_Identifier_Node);
                                 when others =>
                                    Raise_Programmer_Error
                                      ("unhandled rhs_optional case '" & New_Text & "'", Tree, Name_Identifier_Node);
                                 end case;
                                 exit;
                              end if;
                           end if;

                           Temp := Next_List_Element (Temp, +compilation_unit_list_ID);
                           exit when Found or Temp = Invalid_Node_Index;
                        end loop;
                     end;
                  end if;

                  if Found then
                     --  Use previously created nonterminal
                     if Name_Ident /= Invalid_Identifier_Index then
                        Tree.Set_Node_Identifier (Node, +IDENTIFIER_ID, Name_Ident);

                        --  Change RHS_Index, delete Check_EBNF action
                        Tree.Set_Children (Tree.Parent (Node), (+rhs_item_ID, 0), (1 => Node));

                     elsif Name_Terminal /= Invalid_Token_Index then
                        Tree.Set_Children
                          (Tree.Parent (Node),
                           (+rhs_item_ID, 0),
                           (1 => Tree.Add_Terminal (Name_Terminal, Data.Terminals.all)));

                     else
                        raise SAL.Programmer_Error;
                     end if;

                     if Name_Label /= Invalid_Token_Index then
                        declare
                           Label_Node : constant Valid_Node_Index := Tree.Add_Terminal
                             (Name_Label, Data.Terminals.all);
                           Equal_Node : constant Valid_Node_Index := Tree.Add_Terminal (+EQUAL_ID);
                        begin
                           Tree.Set_Children
                             (Tree.Parent (Tree.Parent (Node)),
                              (+rhs_element_ID, 1),
                              (1 => Label_Node,
                               2 => Equal_Node,
                               3 => Tree.Parent (Node)));
                        end;
                     end if;

                  else
                     --  Create a new nonterm, or handle more special cases

                     if List_Singleton (Tree.Child (Node, 2)) then
                        --  Single alternative, multiple rhs_items
                        --
                        --  No separate nonterminal, so token labels stay in the same RHS for
                        --  actions. Splice together rhs_item_lists a, b, c
                        declare
                           Root_List_A    : constant Valid_Node_Index := Tree.Child (Tree.Parent (Node, 3), 1);
                           Tail_Element_A : constant Node_Index       :=
                             (if Root_List_A = Tree.Parent (Node, 2)
                              then Invalid_Node_Index -- a is empty
                              else Last_List_Element (Root_List_A));
                           Root_List_B    : constant Valid_Node_Index := Tree.Child (Tree.Child (Node, 2), 1);
                           Head_Element_B : constant Valid_Node_Index := First_List_Element
                             (Root_List_B, +rhs_element_ID);
                           Tail_Element_B : constant Valid_Node_Index := Last_List_Element (Root_List_B);
                           Root_List_C    : constant Valid_Node_Index := List_Root (Tree.Parent (Node, 3));
                           Head_Element_C : constant Node_Index       := Next_List_Element
                             (Tree.Parent (Node, 2), +rhs_item_list_ID);
                           RHS            : constant Valid_Node_Index := Tree.Parent (Root_List_C);
                           RHS_Children   : Valid_Node_Index_Array    := Tree.Children (RHS);
                        begin
                           if Tail_Element_A = Invalid_Node_Index and Head_Element_C = Invalid_Node_Index then
                              --  A, C both empty
                              RHS_Children (1) := Tree.Child (Root_List_B, 1);
                              Tree.Set_Children (RHS, Tree.Production_ID (RHS), RHS_Children);

                           elsif Tail_Element_A = Invalid_Node_Index then
                              --  A empty, C not empty
                              declare
                                 Parent_B2 : constant Valid_Node_Index := Tree.Parent (Tail_Element_B);
                                 Parent_C  : constant Valid_Node_Index := Tree.Parent (Head_Element_C);
                              begin
                                 Tree.Set_Children (Parent_C, (+rhs_item_list_ID, 1), (Parent_B2, Head_Element_C));
                                 --  Head_Element_C remains the list root.
                              end;

                           elsif Head_Element_C = Invalid_Node_Index then
                              --  A not empty, C empty.
                              declare
                                 Parent_A : constant Valid_Node_Index := Tree.Parent (Tail_Element_A);
                                 Parent_B : constant Valid_Node_Index := Tree.Parent (Head_Element_B);
                              begin
                                 Tree.Set_Children (Parent_B, (+rhs_item_list_ID, 1), (Parent_A, Head_Element_B));
                                 RHS_Children (1) := Root_List_B;
                                 Tree.Set_Children (RHS, Tree.Production_ID (RHS), RHS_Children);
                              end;
                           else
                              --  A, C both not empty
                              declare
                                 Parent_A  : constant Valid_Node_Index := Tree.Parent (Tail_Element_A);
                                 Parent_B1 : constant Valid_Node_Index := Tree.Parent (Head_Element_B);
                                 Parent_B2 : constant Valid_Node_Index := Tree.Parent (Tail_Element_B);
                                 Parent_C  : constant Valid_Node_Index := Tree.Parent (Head_Element_C);
                              begin
                                 Tree.Set_Children (Parent_B1, (+rhs_item_list_ID, 1), (Parent_A, Head_Element_B));
                                 Tree.Set_Children (Parent_C, (+rhs_item_list_ID, 1), (Parent_B2, Head_Element_C));
                                 --  Head_Element_C remains the list root.
                              end;
                           end if;

                           if Trace_Generate > Extra then
                              Ada.Text_IO.New_Line;
                              Ada.Text_IO.Put_Line ("edited rhs:");
                              Tree.Print_Tree (Wisitoken_Grammar_Actions.Descriptor, RHS);
                           end if;
                        end;
                     else
                        declare
                           Nonterm_B : constant Identifier_Index := Next_Nonterm_Name ("");
                        begin
                           New_Nonterminal (Nonterm_B, Tree.Child (Node, 2));
                           Tree.Set_Node_Identifier (Node, +IDENTIFIER_ID, Nonterm_B);
                        end;
                        Tree.Set_Children (Tree.Parent (Node), (+rhs_item_ID, 0), (1 => Node));
                     end if;
                  end if;

               when 2 =>
                  --  | IDENTIFIER QUESTION
                  Tree.Set_Children (Tree.Parent (Node), (+rhs_item_ID, 0), (1 => Tree.Child (Node, 1)));

               when 3 =>
                  --  | STRING_LITERAL_2 QUESTION
                  Tree.Set_Children (Tree.Parent (Node), (+rhs_item_ID, 1), (1 => Tree.Child (Node, 1)));

               when others =>
                  Raise_Programmer_Error ("translate_ebnf_to_bnf rhs_optional_item unimplmented", Tree, Node);
               end case;

               Clear_EBNF_Node (Node);

               Insert_Optional_RHS (Node);
            end;

         when STRING_LITERAL_2_ID =>
            declare
               Value      : constant String  := Get_Text (Data, Tree, Node, Strip_Quotes => True);
               Name_Ident : Identifier_Index;
               Found      : Boolean          := False;
            begin
               --  See if Value is already declared
               declare
                  Temp : Node_Index := First_List_Element (Tree.Child (Tree.Root, 1), +compilation_unit_ID);
                  Decl : Node_Index;
               begin
                  loop
                     pragma Assert (Tree.ID (Temp) = +compilation_unit_ID);

                     if Tree.Production_ID (Tree.Child (Temp, 1)) = (+declaration_ID, 0) then
                        Decl := Tree.Child (Temp, 1);
                        declare
                           Value_Node : constant Valid_Node_Index := Tree.Child (Tree.Child (Decl, 4), 1);
                        begin
                           if Tree.ID (Value_Node) = +declaration_item_ID and then
                             Tree.ID (Tree.Child (Value_Node, 1)) in
                             +IDENTIFIER_ID | +STRING_LITERAL_1_ID | +STRING_LITERAL_2_ID and then
                             Value = Get_Text (Data, Tree, Tree.Child (Value_Node, 1), Strip_Quotes => True)
                           then
                              Found := True;
                              case Tree.Label (Tree.Child (Decl, 3)) is
                              when Shared_Terminal =>
                                 Name_Ident := New_Identifier (Get_Text (Data, Tree, Tree.Child (Decl, 3)));
                              when Virtual_Identifier =>
                                 Name_Ident := Tree.Identifier (Tree.Child (Decl, 3));
                              when others =>
                                 raise SAL.Programmer_Error;
                              end case;
                           end if;
                        end;
                     end if;

                     Temp := Next_List_Element (Temp, +compilation_unit_list_ID);
                     exit when Temp = Invalid_Node_Index;
                  end loop;
               end;

               if not Found then
                  if GNAT.Regexp.Match (Value, Symbol_Regexp) then
                     Name_Ident := New_Identifier (Ada.Characters.Handling.To_Upper (Value));
                  else
                     Put_Error
                       (Error_Message
                          (Data.Grammar_Lexer.File_Name, Get_Line (Data, Tree, Node),
                           "punctuation token '" & Value & "' not declared"));
                     return;
                  end if;
               end if;

               declare
                  Parent : constant Valid_Node_Index := Tree.Parent (Node);
               begin
                  case To_Token_Enum (Tree.ID (Parent)) is
                  when rhs_item_ID =>
                     Tree.Set_Children
                       (Tree.Parent (Node),
                        (+rhs_item_ID, 0),
                        (1 => Tree.Add_Identifier (+IDENTIFIER_ID, Name_Ident, Tree.Byte_Region (Node))));

                  when rhs_optional_item_ID =>
                     Tree.Set_Children
                       (Tree.Parent (Node),
                        (+rhs_optional_item_ID, 2),
                        (1 => Tree.Add_Identifier (+IDENTIFIER_ID, Name_Ident, Tree.Byte_Region (Node))));

                  when others =>
                     Raise_Programmer_Error ("translate_ebnf_to_bnf string_literal_2 unimplemented", Tree, Node);
                  end case;
               end;

               Clear_EBNF_Node (Node);
               if Found then return; end if;

               --  Declare token for keyword string literal
               declare
                  Keyword        : constant Valid_Node_Index := Tree.Add_Identifier
                    (+KEYWORD_ID, Keyword_Ident, Tree.Byte_Region (Node));
                  Kind           : constant Valid_Node_Index := Tree.Add_Nonterm
                    ((+token_keyword_non_grammar_ID, 0),
                     (1 => Keyword));
                  Value_Literal  : constant Valid_Node_Index := Tree.Add_Identifier
                    (+STRING_LITERAL_1_ID, New_Identifier ('"' & Value & '"'), Tree.Byte_Region (Node));
                  Decl_Item      : constant Valid_Node_Index := Tree.Add_Nonterm
                    ((+declaration_item_ID, 1),
                     (1 => Value_Literal));
                  Decl_Item_List : constant Valid_Node_Index := Tree.Add_Nonterm
                    ((+declaration_item_list_ID, 0),
                     (1 => Decl_Item));

                  Percent : constant Valid_Node_Index := Tree.Add_Identifier
                    (+PERCENT_ID, Percent_Ident, Tree.Byte_Region (Node));
                  Name    : constant Valid_Node_Index := Tree.Add_Identifier
                    (+IDENTIFIER_ID, Name_Ident, Tree.Byte_Region (Node));
                  Decl    : constant Valid_Node_Index := Tree.Add_Nonterm
                    ((+declaration_ID, 0), (Percent, Kind, Name, Decl_Item_List), Action => declaration_0'Access);
               begin
                  Add_Compilation_Unit (Decl, Prepend => True);
               end;
            end;

         when others =>
            Raise_Programmer_Error ("unimplemented EBNF node", Tree, Node);
         end case;
      exception
      when SAL.Programmer_Error =>
         raise;
      when E : others =>
         Raise_Programmer_Error
           ("unhandled exception " & Ada.Exceptions.Exception_Name (E) & ": " &
              Ada.Exceptions.Exception_Message (E),
            Tree, Node);
      end Process_Node;

   begin
      --  Process nodes in node increasing order, so contained items are
      --  translated first, so duplicates of the containing item can be found
      for I in Data.EBNF_Nodes.First_Index .. Data.EBNF_Nodes.Last_Index loop
         if Data.EBNF_Nodes (I) then
            Process_Node (I);
         end if;
      end loop;

      --  Processing copied nodes may produce more copied nodes, so we can't
      --  use a 'for' loop.
      declare
         use all type SAL.Base_Peek_Type;
         I : SAL.Base_Peek_Type := Copied_EBNF_Nodes.First_Index;
      begin
         loop
            exit when I > Copied_EBNF_Nodes.Last_Index;
            Process_Node (Copied_EBNF_Nodes (I));
            I := I + 1;
         end loop;
      end;

      Data.Meta_Syntax := BNF_Syntax;

      if Trace_Generate > Detail then
         Ada.Text_IO.New_Line;
         Ada.Text_IO.Put_Line ("Identifiers:");
         for I in Data.Tokens.Virtual_Identifiers.First_Index .. Data.Tokens.Virtual_Identifiers.Last_Index loop
            Ada.Text_IO.Put_Line (Base_Identifier_Index'Image (I) & " " & (-Data.Tokens.Virtual_Identifiers (I)));
         end loop;
      end if;
   exception
   when E : SAL.Not_Implemented =>
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error, "Translate_EBNF_To_BNF not implemented: " & Ada.Exceptions.Exception_Message (E));
   end Translate_EBNF_To_BNF;

   procedure Print_Source
     (File_Name : in String;
      Tree      : in WisiToken.Syntax_Trees.Tree;
      Data      : in User_Data_Type)
   is
      use Ada.Text_IO;
      use WisiToken.Syntax_Trees;
      File                     : File_Type;
      Comments_Include_Newline : Boolean;

      procedure Put_Comments (Node : in Valid_Node_Index)
      is
         Token : constant Base_Token_Index := Tree.Max_Terminal_Index (Node);
      begin
         --  Not all tokens have trailing non_grammar, so Data.Non_Grammar may
         --  not have entries for every token.
         Comments_Include_Newline := False;
         if Token /= Invalid_Token_Index and then
           Token in Data.Non_Grammar.First_Index .. Data.Non_Grammar.Last_Index
         then
            declare
               Tokens : Base_Token_Arrays.Vector renames Data.Non_Grammar (Token);
            begin
               for Token of Tokens loop
                  if Token.ID = +NEW_LINE_ID then
                     Comments_Include_Newline := True;
                  end if;
                  Put (File, Data.Grammar_Lexer.Buffer_Text (Token.Byte_Region));
               end loop;
            end;
         end if;
      end Put_Comments;

      procedure Put_Declaration_Item (Node : in Valid_Node_Index)
      is
         Children : constant Valid_Node_Index_Array := Tree.Children (Node);
      begin
         case To_Token_Enum (Tree.ID (Children (1))) is
         when IDENTIFIER_ID | NUMERIC_LITERAL_ID | STRING_LITERAL_1_ID | STRING_LITERAL_2_ID =>
            Put (File, ' ' & Get_Text (Data, Tree, Children (1)));
         when REGEXP_ID =>
            Put (File, " %[" & Get_Text (Data, Tree, Children (1)) & "]%");
         when others =>
            Put (File, Image (Tree.ID (Children (1)), Wisitoken_Grammar_Actions.Descriptor));
         end case;
      end Put_Declaration_Item;

      procedure Put_Declaration_Item_List (Node : in Valid_Node_Index)
      is
         Children : constant Valid_Node_Index_Array := Tree.Children (Node);
      begin
         if Children'Length = 1 then
            Put_Declaration_Item (Children (1));
         else
            Put_Declaration_Item_List (Children (1));
            Put_Declaration_Item (Children (2));
         end if;
      end Put_Declaration_Item_List;

      procedure Put_Identifier_List (Node : in Valid_Node_Index)
      is
         Children : constant Valid_Node_Index_Array := Tree.Children (Node);
      begin
         if Children'Length = 1 then
            Put (File, Get_Text (Data, Tree, Children (1)));
         else
            Put_Identifier_List (Children (1));
            Put (File, ' ');
            Put (File, Get_Text (Data, Tree, Children (2)));
         end if;
      end Put_Identifier_List;

      procedure Put_RHS_Element (Node : in Valid_Node_Index)
      with Pre => Tree.ID (Node) = +rhs_element_ID
      is begin
         --  We don't raise an exception for errors here; it's easier to debug from the
         --  mangled source listing.

         case Tree.RHS_Index (Node) is
         when 0 =>
            Put (File, Get_Text (Data, Tree, Node));

         when 1 =>
            --  Output no spaces around "="
            declare
               Children : constant Valid_Node_Index_Array := Tree.Children (Node);
            begin
               Put (File, Get_Text (Data, Tree, Children (1)) & "=" & Get_Text (Data, Tree, Children (3)));
            end;

         when others =>
            New_Line (File);
            Put (File, " ;; not translated: " & Node_Index'Image (Node) & ":" &
              Tree.Image (Node, Wisitoken_Grammar_Actions.Descriptor, Include_Children => True));
         end case;
      exception
      when SAL.Programmer_Error =>
         raise;

      when E : others =>
         declare
            use Ada.Exceptions;
         begin
            Raise_Programmer_Error
              ("Put_RHS_Element: " & Exception_Name (E) & ": " & Exception_Message (E), Tree, Node);
         end;
      end Put_RHS_Element;

      procedure Put_RHS_Item_List (Node : in Valid_Node_Index)
      with Pre => Tree.ID (Node) = +rhs_item_list_ID
      is
         Children : constant Valid_Node_Index_Array := Tree.Children (Node);
      begin
         if Children'Length = 1 then
            Put_RHS_Element (Children (1));
         else
            Put_RHS_Item_List (Children (1));
            Put (File, ' ');
            Put_RHS_Element (Children (2));
         end if;
      exception
      when SAL.Programmer_Error =>
         raise;

      when E : others =>
         declare
            use Ada.Exceptions;
         begin
            Raise_Programmer_Error
              ("Put_RHS_Item_List: " & Exception_Name (E) & ": " & Exception_Message (E), Tree, Node);
         end;
      end Put_RHS_Item_List;

      procedure Put_RHS
        (Node    : in Valid_Node_Index;
         First   : in Boolean;
         Virtual : in Boolean)
      with Pre => Tree.ID (Node) = +rhs_ID
      is
         Children : constant Valid_Node_Index_Array := Tree.Children (Node);
      begin
         Put (File, (if First then "  : " else "  | "));
         case Tree.RHS_Index (Node) is
         when 0 =>
            if Virtual then
               Put_Line (File, ";; empty");
            else
               Put_Comments (Tree.Parent (Node));
            end if;

         when 1 .. 3 =>
            Put_RHS_Item_List (Children (1));
            if Virtual then
               New_Line (File);
            else
               Put_Comments (Children (1));
            end if;

            if Tree.RHS_Index (Node) > 1 then
               Put (File, "    %(" & Get_Text (Data, Tree, Children (2)) & ")%"); -- action
               if Virtual then
                  New_Line (File);
               else
                  Put_Comments (Children (2));
               end if;
               if Tree.RHS_Index (Node) > 2 then
                  Put (File, "    %(" & Get_Text (Data, Tree, Children (3)) & ")%"); -- check
                  if Virtual then
                     New_Line (File);
                  else
                     Put_Comments (Children (3));
                  end if;
               end if;
            end if;

         when others =>
            Raise_Programmer_Error ("Put_RHS", Tree, Node);
         end case;
      exception
      when SAL.Programmer_Error =>
         raise;

      when E : others =>
         declare
            use Ada.Exceptions;
         begin
            Raise_Programmer_Error ("Put_RHS: " & Exception_Name (E) & ": " & Exception_Message (E), Tree, Node);
         end;
      end Put_RHS;

      procedure Put_RHS_List
        (Node    : in     Valid_Node_Index;
         First   : in out Boolean;
         Virtual : in     Boolean)
      with Pre => Tree.ID (Node) = +rhs_list_ID
      is
         Children : constant Valid_Node_Index_Array := Tree.Children (Node);
      begin
         case Tree.RHS_Index (Node) is
         when 0 =>
            Put_RHS (Children (1), First, Virtual or Children (1) > Data.EBNF_Nodes.Last_Index);
            First := False;
         when 1 =>
            Put_RHS_List (Children (1), First, Virtual);
            Put_RHS (Children (3), First => False, Virtual => Virtual or Children (3) > Data.EBNF_Nodes.Last_Index);
         when 2 =>
            Put
              (File, "%if " & Get_Text (Data, Tree, Children (3)) & " = " & Get_Text (Data, Tree, Children (4)));
            Put_Comments (Node);

         when 3 =>
            Put (File, "%end if");
            Put_Comments (Node);

         when others =>
            Raise_Programmer_Error ("Put_RHS_List", Tree, Node);
         end case;
      exception
      when SAL.Programmer_Error =>
         raise;

      when E : others =>
         declare
            use Ada.Exceptions;
         begin
            Raise_Programmer_Error ("Put_RHS_List: " & Exception_Name (E) & ": " & Exception_Message (E), Tree, Node);
         end;
      end Put_RHS_List;

      procedure Process_Node (Node : in Valid_Node_Index)
      is begin
         case To_Token_Enum (Tree.ID (Node)) is
         --  Enum_Token_ID alphabetical order
         when compilation_unit_ID =>
            Process_Node (Tree.Child (Node, 1));

         when compilation_unit_list_ID =>
            declare
               Children : constant Valid_Node_Index_Array := Tree.Children (Node);
            begin
               case To_Token_Enum (Tree.ID (Children (1))) is
               when compilation_unit_list_ID =>
                  Process_Node (Children (1));
                  Process_Node (Children (2));
               when compilation_unit_ID =>
                  Process_Node (Children (1));
               when others =>
                  raise SAL.Programmer_Error;
               end case;
            end;

         when declaration_ID =>
            declare
               Children : constant Valid_Node_Index_Array := Tree.Children (Node);
            begin
               case Tree.RHS_Index (Node) is
               when 0 =>
                  case Tree.RHS_Index (Children (2)) is
                  when 0 =>
                     Put (File, "%keyword");
                  when 1 =>
                     Put (File, "%non_grammar <" & Get_Text (Data, Tree, Tree.Child (Children (2), 3)) & ">");
                  when 2 =>
                     Put (File, "%token <" & Get_Text (Data, Tree, Tree.Child (Children (2), 3)) & ">");
                  when others =>
                     raise SAL.Programmer_Error;
                  end case;

                  Put (File, " " & Get_Text (Data, Tree, Children (3)));
                  Put_Declaration_Item_List (Children (4));
                  if Tree.Is_Virtual (Children (4)) then
                     New_Line (File);
                  else
                     Put_Comments (Children (4));
                  end if;

               when 1 =>
                  Put (File, "%code ");
                  Put_Identifier_List (Children (3));
                  Put (File, " %{" & Get_Text (Data, Tree, Children (4)) & "}%"); -- RAW_CODE
                  Put_Comments (Node);

               when 2 =>
                  declare
                     Key : constant String := Get_Text (Data, Tree, Children (2));
                  begin
                     if Key = "conflict" then
                        Put (File, Data.Grammar_Lexer.Buffer_Text (Tree.Byte_Region (Node)));
                     else
                        Put (File, "%" & Key);
                        Put_Declaration_Item_List (Children (3));
                     end if;
                  end;
                  Put_Comments (Children (3));

               when 3 =>
                  Put (File, "%" & Get_Text (Data, Tree, Children (2)));
                  Put_Comments (Children (2));

               when 4 =>
                  Put
                    (File, "%if" & Get_Text (Data, Tree, Children (2)) & " = " & Get_Text (Data, Tree, Children (4)));
                  Put_Comments (Node);

               when 5 =>
                  Put (File, "%end if");
                  Put_Comments (Node);

               when others =>
                  raise SAL.Programmer_Error;
               end case;
            end;

         when nonterminal_ID =>
            declare
               Children : constant Valid_Node_Index_Array := Tree.Children (Node);
               Virtual  : constant Boolean                := Tree.Label (Children (1)) = Virtual_Identifier;
               First    : Boolean                         := True;
            begin
               Put (File, Get_Text (Data, Tree, Children (1)));
               if Virtual then
                  New_Line (File);
               else
                  Put_Comments (Children (1));
                  if not Comments_Include_Newline then
                     New_Line (File);
                  end if;
               end if;

               Put_RHS_List (Children (3), First, Virtual);

               if Tree.Children (Children (4))'Length > 0 then
                  if Virtual then
                     Put_Line (File, "  ;");
                  else
                     Put (File, "  ;");
                     Put_Comments (Children (4));
                  end if;
               end if;
            end;

         when wisitoken_accept_ID =>
            Process_Node (Tree.Child (Node, 1));

         when others =>
            raise SAL.Not_Implemented with Image (Tree.ID (Node), Wisitoken_Grammar_Actions.Descriptor);
         end case;
      end Process_Node;
   begin
      Create (File, Out_File, File_Name);
      Put_Line (File, ";;; generated from " & Data.Grammar_Lexer.File_Name & " -*- buffer-read-only:t -*-");
      Put_Line (File, ";;;");

      declare
         Tokens : Base_Token_Arrays.Vector renames Data.Non_Grammar (0);
      begin
         for Token of Tokens loop
            Put (File, Data.Grammar_Lexer.Buffer_Text (Token.Byte_Region));
         end loop;
      end;

      Process_Node (Tree.Root);

      Close (File);
   exception
   when E : SAL.Not_Implemented =>
      Close (File);
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error, "Print_Source not implemented: " & Ada.Exceptions.Exception_Message (E));
   end Print_Source;

end WisiToken_Grammar_Runtime;
--  Local Variables:
--  ada-which-func-parse-size: 30000
--  End:
