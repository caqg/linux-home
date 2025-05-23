--  Abstract :
--
--  Output Ada code implementing the grammar defined by input
--  parameters, and a parser for that grammar. The parser actions
--  assume the Emacs Ada mode wisi indentation engine
--
--  If run in a separate process communicating over pipes with the
--  Emacs process, the parser actions output encoded elisp actions;
--  the protocol is documented in Emacs Ada mode wisi-process-parse.el,
--  function wisi-process-parse-execute.
--
--  If run in an Emacs dynamically loaded module, the parser actions
--  call the elisp actions directly.
--
--  Copyright (C) 2012 - 2015, 2017 - 2022 Free Software Foundation, Inc.
--
--  The WisiToken package is free software; you can redistribute it
--  and/or modify it under terms of the GNU General Public License as
--  published by the Free Software Foundation; either version 3, or
--  (at your option) any later version. This library is distributed in
--  the hope that it will be useful, but WITHOUT ANY WARRANTY; without
--  even the implied warranty of MERCHANTABILITY or FITNESS FOR A
--  PARTICULAR PURPOSE.
--
--  As a special exception under Section 7 of GPL version 3, you are granted
--  additional permissions described in the GCC Runtime Library Exception,
--  version 3.1, as published by the Free Software Foundation.

pragma License (Modified_GPL);

with Ada.Exceptions;
with Ada.Strings.Fixed;
with Ada.Strings.Maps;
with Ada.Text_IO; use Ada.Text_IO;
with WisiToken.BNF.Generate_Packrat;
with WisiToken.BNF.Generate_Utils;
with WisiToken.BNF.Output_Ada_Common; use WisiToken.BNF.Output_Ada_Common;
with WisiToken.BNF.Output_Elisp_Common; use WisiToken.BNF.Output_Elisp_Common;
with WisiToken.Generate.Packrat;
with WisiToken_Grammar_Runtime;
procedure WisiToken.BNF.Output_Ada_Emacs
  (Input_Data            :         in WisiToken_Grammar_Runtime.User_Data_Type;
   Grammar_File_Name     :         in String;
   Output_File_Name_Root :         in String;
   Generate_Data         : aliased in WisiToken.BNF.Generate_Utils.Generate_Data;
   Packrat_Data          :         in WisiToken.Generate.Packrat.Data;
   Tuple                 :         in Generate_Tuple;
   Test_Main             :         in Boolean;
   Multiple_Tuples       :         in Boolean;
   Language_Name         :         in String)
is
   use all type Ada.Containers.Count_Type;

   Default_Language_Runtime_Package : constant String := "Wisi." & Language_Name;

   Blank_Set : constant Ada.Strings.Maps.Character_Set := Ada.Strings.Maps.To_Set (" ");
   Numeric   : constant Ada.Strings.Maps.Character_Set := Ada.Strings.Maps.To_Set ("0123456789");

   Common_Data : Output_Ada_Common.Common_Data := WisiToken.BNF.Output_Ada_Common.Initialize
     (Input_Data, Tuple, Grammar_File_Name, Output_File_Name_Root, Check_Interface => True);

   Gen_Alg_Name : constant String :=
     (if Test_Main or Multiple_Tuples
      then "_" & WisiToken.BNF.Generate_Algorithm_Image (Common_Data.Generate_Algorithm).all
      else "");

   function Split_Sexp
     (Item            : in String;
      Input_File_Name : in String;
      Source_Line     : in WisiToken.Line_Number_Type)
     return String_Lists.List
   is
      --  Return one sexp per element. Remove comments, newlines, and outer '(progn )'.

      use WisiToken.Generate;

      Progn_Index : constant Integer := Ada.Strings.Fixed.Index (Item, "(progn");

      Item_I : Integer := Item'First;

      Buffer       : String (Item'First .. Item'Last);
      Buffer_J     : Integer := Buffer'First;
      Buffer_First : Integer := Buffer'First;
      Paren_Count  : Integer := 0;
      In_Comment   : Boolean := False;
      Result       : String_Lists.List;

      Delete_Last_Paren : Boolean := False;
   begin
      --  Loop thru Item, copying chars to Buffer, replacing comments and
      --  newlines with a single space each.

      if 0 /= Progn_Index then
         Item_I := Progn_Index + 6;

         Delete_Last_Paren := True;
      end if;

      loop
         exit when Item_I > Item'Last;

         if In_Comment then
            if Item (Item_I) in ASCII.CR | ASCII.LF then
               In_Comment := False;
               Buffer (Buffer_J) := ' ';
               Buffer_J := Buffer_J + 1;
            end if;
         else
            if Item (Item_I) = '(' then
               if Paren_Count = 0 then
                  Buffer_First := Buffer_J;
               end if;
               Paren_Count := Paren_Count + 1;

               Buffer (Buffer_J) := Item (Item_I);
               Buffer_J := Buffer_J + 1;

            elsif Item (Item_I) = ')' then
               Paren_Count := Paren_Count - 1;
               if Paren_Count = 0 then
                  Buffer (Buffer_J) := Item (Item_I);
                  Result.Append (Buffer (Buffer_First .. Buffer_J));
                  Buffer_First := Buffer'First;
                  Buffer_J     := Buffer'First;

               elsif Paren_Count = -1 then
                  if Delete_Last_Paren then
                     --  all done
                     return Result;
                  else
                     Put_Error (Error_Message (Input_File_Name, Source_Line, "mismatched parens"));
                     return String_Lists.Empty_List;
                  end if;
               else
                  Buffer (Buffer_J) := Item (Item_I);
                  Buffer_J := Buffer_J + 1;
               end if;

            elsif Item (Item_I) in ASCII.CR | ASCII.LF then
               Buffer (Buffer_J) := ' ';
               Buffer_J := Buffer_J + 1;

            elsif Item (Item_I) = ';' and then Item_I < Item'Last and then Item (Item_I + 1) = ';' then
               In_Comment := True;

            else
               Buffer (Buffer_J) := Item (Item_I);
               Buffer_J := Buffer_J + 1;
            end if;
         end if;
         Item_I := Item_I + 1;
      end loop;
      if Paren_Count /= 0 then
         Put_Error
           (Error_Message
              (Input_File_Name, Source_Line, "mismatched parens"));
      end if;
      return Result;
   end Split_Sexp;

   procedure Create_Ada_Action
     (Name          : in     String;
      RHS           : in     RHS_Type;
      Prod_ID       : in     WisiToken.Production_ID;
      Unsplit_Lines : in     Ada.Strings.Unbounded.Unbounded_String;
      Labels        : in     String_Arrays.Vector;
      Empty         :    out Boolean;
      Check         : in     Boolean)
   is
      --  Create Action (if Check = False; Lines must be RHS.Action) or
      --  Check (if Check = True; Lines must be RHS.Check) subprogram named
      --  Name for RHS.

      use Ada.Strings;
      use Ada.Strings.Fixed;
      use Ada.Strings.Unbounded;
      use WisiToken.Generate;

      Sexps : constant String_Lists.List := Split_Sexp
        (-Unsplit_Lines, Grammar_File_Name, RHS.Source_Line);

      use all type Ada.Strings.Maps.Character_Set;

      Space_Paren_Set : constant Ada.Strings.Maps.Character_Set :=
        Ada.Strings.Maps.To_Set ("])") or Blank_Set;

      Navigate_Lines     : String_Lists.List;
      Face_Line          : Unbounded_String;
      Indent_Action_Line : Unbounded_String;
      Check_Line         : Unbounded_String;

      Label_Needed   : array (Labels.First_Index .. Labels.Last_Index) of Boolean := (others => False);
      Nonterm_Needed : Boolean := False;

      Last_Token_Index : Base_Identifier_Index := 0;
      function Next_Token_Label return String
      is begin
         --  Only called from Indent_Params when RHS.Auto_Token_Labels is True.
         Last_Token_Index := @ + 1;
         return "T" & Trimmed_Image (Last_Token_Index);
      end Next_Token_Label;

      function Get_Label (Token_Param : in String; Integer : in Boolean := False) return String
      is begin
         if RHS.Auto_Token_Labels then
            return
              (if Integer
               then "Integer (T" & Token_Param & ")"
               else "T" & Token_Param);
         else
            return Token_Param;
         end if;
      end Get_Label;

      procedure Mark_Label_Used (Label : in String)
      is begin
         for I in Labels.First_Index .. Labels.Last_Index loop
            if Label = Labels (I) then
               Label_Needed (I) := True;
            end if;
         end loop;
      end Mark_Label_Used;

      function Label_Used (Label : in String) return Boolean
      is
         Found : Boolean := False;
      begin
         if 0 = Index (Label, Numeric, Outside) then
            --  Label is an integer, not a label
            return True;
         end if;

         for Tok of RHS.Tokens loop
            if -Tok.Label = Label then
               Found := True;
               exit;
            end if;
         end loop;

         if not Found then
            return False;
         end if;

         for I in Labels.First_Index .. Labels.Last_Index loop
            if Label = Labels (I) then
               Label_Needed (I) := True;
               return True;
            end if;
         end loop;
         raise SAL.Programmer_Error;
      end Label_Used;

      function Find_Token_Index (I : in Base_Identifier_Index) return SAL.Base_Peek_Type
      is
         Rule_Label : constant String := -Labels (I);
      begin
         for I in RHS.Tokens.First_Index .. RHS.Tokens.Last_Index loop
            if Length (RHS.Tokens (I).Label) > 0 and then
              -RHS.Tokens (I).Label = Rule_Label
            then
               return I;
            end if;
         end loop;
         return SAL.Base_Peek_Type'First;
      end Find_Token_Index;

      function Statement_Params (Params : in String) return String
      is
         --  Input looks like: [1 function 2 other ...]
         --  Numbers can be token labels.

         Last       : Integer := Index_Non_Blank (Params); -- skip [
         First      : Integer;
         Second     : Integer;
         Need_Comma : Boolean := False;
         Result     : Unbounded_String;
         Count      : Integer := 0;
      begin
         loop
            First  := Last + 1;
            Second := Index (Params, Blank_Set, First);
            exit when Second = 0;

            Last := Index (Params, Space_Paren_Set, Second + 1);

            declare
               Label : constant String := Get_Label (Params (First .. Second - 1));
            begin
               if Label_Used (Label) then
                  Count := Count + 1;
                  Result := Result & (if Need_Comma then ", " else "") &
                    "(" & Label & ", " &
                    Elisp_Name_To_Ada (Params (Second + 1 .. Last - 1), Append_ID => False, Trim => 0) & ")";

                  Need_Comma := True;
               --  else skip
               end if;
            end;
         end loop;
         Nonterm_Needed := True;
         return " (Parse_Data, Tree, Nonterm, " &
           (case Count is
            when 0 => "(1 .. 0 => (1, Motion)))",
            when 1 => "(1 => " & (-Result) & "))",
            when others =>  "(" & (-Result) & "))");
      end Statement_Params;

      function Motion_Params (Params : in String) return String
      is
         --  Input looks like: [1 [2 EXCEPTION] 3 ...]
         --  Result: (..., Motion_Param_Array'((1, Invalid_Token_ID) & (2, 3) & (3, Invalid_Token_ID))
         use Generate_Utils;
         use Ada.Strings.Maps;

         Delim : constant Character_Set := To_Set ("]") or Blank_Set;

         Last   : Integer          := Index_Non_Blank (Params); -- skip [
         First  : Integer;
         Vector : Boolean;
         Result : Unbounded_String;

         Index_First  : Integer;
         Index_Last   : Integer;
         ID           : Unbounded_String;
         Need_Comma : Boolean := False;
         Count      : Integer          := 0;
      begin
         loop
            if not (Last in Params'First .. Params'Last) then
               Put_Error
                 (Error_Message
                    (Grammar_File_Name, RHS.Source_Line,
                     "Missing ']' or ')'"));
               exit;
            end if;
            Last := Index_Non_Blank (Params, Integer'Min (Params'Last, Last + 1));

            exit when Params (Last) = ']' or Params (Last) = ')';

            Vector := Params (Last) = '[';
            if Vector then
               Index_First := Last + 1;
               Last        := Index (Params, Delim, Index_First);
               Index_Last  := Last - 1;
               First       := Last + 1;
               Last        := Index (Params, Delim, First);
               begin
                  ID := +Trimmed_Image (Find_Token_ID (Generate_Data, Params (First .. Last - 1)));
               exception
               when E : Not_Found =>
                  Put_Error
                    (Error_Message
                       (Grammar_File_Name, RHS.Source_Line,
                        Ada.Exceptions.Exception_Message (E)));
               end;

               declare
                  Label : constant String := Get_Label (Params (Index_First .. Index_Last));
               begin
                  if Label_Used (Label) then
                     --  Ada 2020 added vector aggregates, making this ambiguous without
                     --  Index_ID qualification
                     Result := Result & (if Need_Comma then " & " else "") & "Index_ID'(" &
                       Label & ", " & ID & ")";
                     Need_Comma := True;
                     Count  := Count + 1;
                  end if;
               end;
               if Params (Last) /= ']' then
                  Put_Error
                    (Error_Message
                       (Grammar_File_Name, RHS.Source_Line,
                        "too many token IDs in motion action"));
                  return -Result & "))";
               end if;

            else
               First  := Index_Non_Blank (Params, Last);
               Last   := Index (Params, Delim, First);
               declare
                  Label : constant String := Get_Label (Params (First .. Last - 1));
               begin
                  if Label_Used (Label) then
                     Result := Result & (if Need_Comma then " & " else "") &
                       "Index_ID'(" & Label & ", Invalid_Token_ID)";
                     Need_Comma := True;
                     Count  := Count + 1;
                  end if;
               end;
            end if;
         end loop;
         if Count <= 1 then
            --  No point in calling Motion_Action with only one param.
            return "";
         else
            Nonterm_Needed := True;
            return " (Parse_Data, Tree, Nonterm, (" & (-Result) & "))";
         end if;
      end Motion_Params;

      function Face_Apply_Params (Params : in String) return String
      is
         --  Params is a vector of triples: [1 nil font-lock-keyword-face 3 nil font-lock-function-name-face ...]
         --  Each triple is <token_number> <prefix-face> <suffix-face>.
         --  The token_number can be a label; faces are "nil" or an elisp name.
         --  Result: ((1, 3, 1), (3, 3, 2), ...)
         use Ada.Strings.Maps;
         Delim : constant Character_Set := To_Set ("]") or Blank_Set;

         Last       : Integer := Index_Non_Blank (Params); -- skip [
         First      : Integer;
         Result     : Unbounded_String;
         Need_Comma : Boolean := False;
         Count      : Integer := 0;

         procedure Elisp_Param (Skip : in Boolean)
         is begin
            if Params (Last) = ']' then
               Put_Error
                 (Error_Message
                    (Grammar_File_Name, RHS.Source_Line, "invalid wisi-face-apply argument"));
               return;
            end if;

            First  := Index_Non_Blank (Params, Last + 1);
            Last   := Index (Params, Delim, First);
            if not Skip then
               Result := Result & ',' & Integer'Image
                 (Find_Elisp_ID (Input_Data.Tokens.Faces, Params (First .. Last - 1)));
            end if;
         end Elisp_Param;

      begin
         loop
            Last := Index_Non_Blank (Params, Last + 1);

            exit when Params (Last) = ']' or Params (Last) = ')';

            First := Last;
            Last  := Index (Params, Delim, First);
            declare
               Label : constant String := Get_Label (Params (First .. Last - 1));
            begin
               if Label_Used (Label) then
                  Count  := Count + 1;
                  Result := Result & (if Need_Comma then ", (" else "(") & Label;
                  Need_Comma := True;
                  Elisp_Param (Skip => False);
                  Elisp_Param (Skip => False);
                  Result := Result  & ")";
               else
                  Elisp_Param (Skip => True);
                  Elisp_Param (Skip => True);
               end if;
            end;
         end loop;
         if Count = 0 then
            return "";
         elsif Count = 1 then
               Nonterm_Needed := True;
            return " (Parse_Data, Tree, Nonterm, (1 => " & (-Result) & "))";
         else
               Nonterm_Needed := True;
            return " (Parse_Data, Tree, Nonterm, (" & (-Result) & "))";
         end if;
      exception
      when E : others =>
         Put_Error
           (Error_Message
              (Grammar_File_Name, RHS.Source_Line, "invalid syntax: " &
              Ada.Exceptions.Exception_Message (E)));
         return "";
      end Face_Apply_Params;

      function Face_Mark_Params (Params : in String) return String
      is
         --  Params is a vector of pairs: [1 prefix 3 suffix ...]
         --  The token_number can be a label; faces are "nil" or an elisp name.
         --  Result: ((1, Prefix), (3, Suffix), ...)
         use Ada.Strings.Maps;
         Delim : constant Character_Set := To_Set ("]") or Blank_Set;

         Last       : Integer := Index_Non_Blank (Params); -- skip [
         First      : Integer;
         Result     : Unbounded_String;
         Need_Comma : Boolean := False;
         Count      : Integer := 0;
         Skip       : Boolean;
      begin
         loop
            Last := Index_Non_Blank (Params, Last + 1);

            exit when Params (Last) = ']' or Params (Last) = ')';

            First := Last;
            Last  := Index (Params, Delim, First);
            declare
               Label : constant String := Get_Label (Params (First .. Last - 1));
            begin
               if Label_Used (Label) then
                  Count  := Count + 1;
                  Skip   := False;
                  Result := Result & (if Need_Comma then ", (" else "(") & Label;
               else
                  Skip := True;
               end if;
            end;

            if Params (Last) = ']' then
               Put_Error
                 (Error_Message
                    (Grammar_File_Name, RHS.Source_Line, "invalid wisi-face-mark argument"));
               exit;
            end if;

            First  := Index_Non_Blank (Params, Last + 1);
            Last   := Index (Params, Delim, First);
            if not Skip then
               Result := Result & ", " & Elisp_Name_To_Ada (Params (First .. Last - 1), False, 0) & ")";
               Need_Comma := True;
            end if;
         end loop;
         Nonterm_Needed := True;
         return " (Parse_Data, Tree, Nonterm, " &
           (case Count is
            when 0 => "(1 .. 0 => (1, Prefix))",
            when 1 => "(1 => " & (-Result) & "))",
            when others => "(" & (-Result) & "))");
      exception
      when E : others =>
         Put_Error
           (Error_Message
            (Grammar_File_Name, RHS.Source_Line, "invalid syntax: " &
              Ada.Exceptions.Exception_Message (E)));
         return "";
      end Face_Mark_Params;

      function Face_Remove_Params (Params : in String) return String
      is
         --  Params is a vector of token numbers: [1 3 ...]
         --  Token numbers can be labels.
         --  Result: (1, 3, ...)
         use Ada.Strings.Maps;
         Delim : constant Character_Set := To_Set ("]") or Blank_Set;

         Last       : Integer := Index_Non_Blank (Params); -- skip [
         First      : Integer;
         Result     : Unbounded_String;
         Need_Comma : Boolean := False;
         Count      : Integer := 0;
      begin
         loop
            Last := Index_Non_Blank (Params, Last + 1);

            exit when Params (Last) = ']' or Params (Last) = ')';

            First  := Last;
            Last   := Index (Params, Delim, First);
            declare
               Label : constant String := Get_Label (Params (First .. Last - 1));
            begin
               if Label_Used (Label) then
                  Count      := Count + 1;
                  Result     := Result & (if Need_Comma then ", " else "") & Label;
                  Need_Comma := True;
               end if;
            end;
         end loop;
         Nonterm_Needed := True;
         return " (Parse_Data, Tree, Nonterm, " &
           (case Count is
            when 0 => "(1 .. 0 => 1)",
            when 1 => "(1 => " & (-Result) & "))",
            when others => "(" & (-Result) & "))");
      exception
      when E : others =>
         Put_Error
           (Error_Message
            (Grammar_File_Name, RHS.Source_Line, "invalid syntax: " &
              Ada.Exceptions.Exception_Message (E)));
         return "";
      end Face_Remove_Params;

      function Indent_Params (Params : in String; N : in String := "") return String
      is
         --  If N is non-empty, it is the first arg in wisi-indent-action*, followed by ','.
         --
         --  Params is a vector, one item for each token in Tokens. Each item is one of:
         --
         --  - an integer; copy to output
         --
         --  - a symbol; convert to Ada name syntax, except 'nil' => None
         --
         --  - a lisp function call with arbitrary args; convert to Indent_Param type
         --
         --  - a vector with two elements [code_indent comment_indent]; convert to Indent_Pair.
         --
         --  - a cons of a token label with any of the above.

         use Ada.Strings.Maps;
         use Ada.Containers;

         Delim : constant Character_Set := To_Set ("])") or Blank_Set;

         subtype Digit is Character range '0' .. '9';

         Last       : Integer         := Index_Non_Blank (Params); -- skip [
         Prefix     : constant String := " (Parse_Data, Tree, Nonterm, " & N & "(";
         Result     : Unbounded_String;
         Need_Comma : Boolean         := False;

         --  In translated EBNF, token counts vary in each RHS, but the indent
         --  parameter list is copied from the original. So the tokens don't
         --  match the indent params. First we build a list of (label, value)
         --  for parameters present in Params, then we match them against
         --  RHS.Tokens.
         Param_List : String_Pair_Lists.List;

         function Indent_Function (Elisp_Name : in String) return String
         is begin
            if    Elisp_Name = "wisi-anchored"  then return "Anchored_0";
            elsif Elisp_Name = "wisi-anchored%" then return "Anchored_1";
            elsif Elisp_Name = "wisi-block"     then return "Block";
            elsif Elisp_Name = "wisi-hanging"   then return "Hanging_0";
            elsif Elisp_Name = "wisi-hanging%"  then return "Hanging_1";
            elsif Elisp_Name = "wisi-hanging*"  then return "Hanging_2";
            else
               Put_Error
                 (Error_Message
                  (Grammar_File_Name, RHS.Source_Line, "unrecognized wisi indent function: '" &
                    Elisp_Name & "'"));
               return "";
            end if;
         end Indent_Function;

         function Check_Cons return Integer
         is
            --  Params (Last) = '('; check for "(label .", return label'last
            Blank : constant Integer := Index (Params, " ", Last);
         begin
            if Blank = 0 then return 0; end if;
            if Params'Last > Blank + 1 and then Params (Blank + 1) = '.' then
               return Blank - 1;
            else
               return 0;
            end if;
         end Check_Cons;

         function Ensure_Simple_Indent (Item : in String) return String
         is begin
            --  Return an aggregate for Simple_Indent_Param. Item can be anything
            --  Expression returns except Hanging.

            if Item (Item'First) = '(' then
               --  Anchored or Language
               return Item;

            elsif Item = "nil" then
               return "(Label => None)";

            else
               --  simple integer
               return "(Int, " & Item & ")";
            end if;
         end Ensure_Simple_Indent;

         function Expression (Param_First : in Integer) return String
         is
            --  Return a simple integer expression, or an aggregate for
            --  Simple_Indent_Param or Indent_Param.
            --
            --  Handles this syntax:
            --
            --  nil => nil
            --
            --  integer literal:
            --  2 => 2
            --  -1 => -1
            --
            --  variable name:
            --  ada-indent => Ada_Indent
            --
            --  token_id literal:
            --  'TYPE => 13
            --
            --  simple expression with + - * :
            --  (- ada-indent) => -Ada_Indent
            --  (- ada-indent-when ada-indent) => Ada_Indent_When - Ada_Indent
            --
            --  if expression:
            --  (if c a b) => (if c then a else b)
            --
            --  function call with expression args:
            --  (wisi-hanging (wisi-anchored% 1 ada-indent)
            --                (wisi-anchored% 1 (+ ada-indent ada-indent-broken)))

            use Generate_Utils;

            First : Integer := Index_Non_Blank (Params, Param_First);

            Function_Name : Unbounded_String;
            Args          : Unbounded_String;
            Arg_Count     : Count_Type := 0;
         begin
            if Params (First) in Digit or Params (First) = '-' then
               Last := Index (Params, Delim, First);
               return Params (First .. Last - 1);

            elsif Params (First) = ''' then
               Last := Index (Params, Delim, First);
               return WisiToken.Trimmed_Image (Find_Token_ID (Generate_Data, Params (First + 1 .. Last - 1)));

            elsif Params (First) = '(' then
               First  := First + 1;
               Last   := Index (Params, Delim, First);
               Function_Name := +Params (First .. Last - 1);

               if Length (Function_Name) = 1 then
                  --  - + *
                  Last := Index (Params, Delim, Last + 1);
                  if Params (Last) = ')' then
                     return Result : constant String := -Function_Name & Expression (First + 1)
                     do
                        Last := Last + 1; -- get past ')'
                     end return;
                  else
                     Args := +Expression (First + 1);
                     Args := Args & ' ' & Function_Name & ' ' & Expression (Last + 1);

                     Last := Last + 1; -- get past ')'
                     return -Args;
                  end if;

               elsif -Function_Name = "if" then
                  Args := +Expression (Last + 1);
                  Args := +"(if " & Args & " then " & Expression (Last + 1);
                  Args := Args & " else " & Expression (Last + 1) & ')';

                  Last := Last + 1; -- get past ')'
                  return -Args;

               elsif Input_Data.Tokens.Indents.Contains (Function_Name) then
                  --  Language-specific indent function call
                  declare
                     Pair : String_Pair_Type renames Input_Data.Tokens.Indents.Constant_Reference (Function_Name);

                     Declared_Args       : constant String := -Pair.Value;
                     Declared_Args_First : Integer         := Declared_Args'First;
                     Declared_Args_Last  : Integer         := Index (Declared_Args, Blank_Set);

                     Declared_Arg_Count : Count_Type := 0;
                     Next_Token_Arg     : Count_Type := 0;

                     procedure Get_Next_Token_Arg
                     is begin
                        Declared_Args_First := Index_Non_Blank (Declared_Args, Declared_Args_Last + 1);
                        if Declared_Args_First /= 0 then
                           Declared_Args_Last := Index (Declared_Args, Blank_Set, Declared_Args_First);
                           if Declared_Args_Last = 0 then
                              Declared_Args_Last := Declared_Args'Last;
                           end if;

                           Next_Token_Arg := Count_Type'Value
                             (Declared_Args (Declared_Args_First .. Declared_Args_Last));
                        end if;
                     end Get_Next_Token_Arg;

                  begin
                     if Declared_Args'Length = 0 then
                        --  grammar file not updated to current wisitoken version
                        Put_Error
                          (Error_Message
                             (Grammar_File_Name, RHS.Source_Line,
                              "%elisp_indent function requires arg count, token index args."));
                     else
                        if Declared_Args_Last = 0 then
                           Declared_Args_Last := Declared_Args'Last;
                        end if;

                        Declared_Arg_Count  := Count_Type'Value
                          (Declared_Args (Declared_Args_First .. Declared_Args_Last));

                        Get_Next_Token_Arg;
                     end if;

                     Function_Name := Pair.Name; -- Ada name
                     Arg_Count     := 0;
                     loop
                        exit when Params (Last) = ')';

                        First     := Last + 1;
                        Arg_Count := Arg_Count + 1;

                        Args := @ & (if Arg_Count = 1 then "" else " & ");

                        if Next_Token_Arg = Arg_Count then
                           Args := @ & Get_Label (Expression (First), Integer => True);
                           Get_Next_Token_Arg;

                        else
                           Args := @ & Expression (First);
                        end if;
                     end loop;

                     if Declared_Arg_Count /= Arg_Count then
                        Put_Error
                          (Error_Message
                             (Grammar_File_Name,
                              RHS.Source_Line,
                              "declared " & (-Function_Name) & " parameter count" & Declared_Arg_Count'Image &
                                " /= actual parameter count" & Arg_Count'Image));
                     end if;

                     Last := Last + 1; -- get past ')'

                     return "(Language, " & (-Function_Name) & "'Access, " &
                       (if Arg_Count = 0 then "Null_Args"
                        elsif Arg_Count = 1 then '+' & (-Args)
                        else -Args)
                       & ')';
                  end;

               else
                  --  wisi lisp function call
                  Function_Name := +Indent_Function (-Function_Name);
                  if Length (Function_Name) = 0 then
                     --  not a recognized function
                     Last := 1 + Index (Params, ")", Last);
                     return "";

                  elsif Slice (Function_Name, 1, 4) = "Hang" then
                     --  Arguments are 2 Simple_Indent_Param
                     Args := +Ensure_Simple_Indent (Expression (Last + 1));
                     Args := Args & ", " & Ensure_Simple_Indent (Expression (Last + 1));
                     Last := Last + 1; -- get past ')'
                     return "(" & (-(Function_Name & ", " & Args)) & ")";

                  elsif Function_Name = "Block" then
                     --  Argument is 1 simple integer expression; delta
                     Args := +Expression (Last + 1);
                     Last := Last + 1; -- get past ')'
                     return "(" & (-(Function_Name & ", " & Args)) & ")";

                  elsif Slice (Function_Name, 1, 4) = "Anch" then
                     --  Arguments are 2 simple integer expressions; token delta
                     Args := +Get_Label (Expression (Last + 1));
                     Args := Args & ", " & Expression (Last + 1);
                     Last := Last + 1; -- get past ')'
                     return "(" & (-(Function_Name & ", " & Args)) & ")";

                  else
                     Put_Error
                       (Error_Message
                          (Grammar_File_Name, RHS.Source_Line,
                           "unimplimented wisi indent function: '" & (-Function_Name) & "'"));
                     return -Function_Name;
                  end if;
               end if;

            else
               --  Assume it is 'nil' or a language-specific integer indent option,
               --  like "ada-indent", declared in Language_Runtime_Package, which is
               --  use-visible.
               Last  := Index (Params, Delim, First);
               if Params (First .. Last - 1) = "nil" then
                  return "nil";
               else
                  return Elisp_Name_To_Ada (Params (First .. Last - 1), False, 0);
               end if;
            end if;
         exception
         when E : others =>
            Put_Error
              (Error_Message
                 (Grammar_File_Name, RHS.Source_Line, Ada.Exceptions.Exception_Message (E)));
            return "";
         end Expression;

         function Ensure_Indent_Param (Item : in String) return String
         is begin
            --  Return an aggregate for Indent_Param. Item can be anything
            --  Expression returns.
            if Item'Length = 0 then
               --  Expression could not find an indent function
               return Item;

            elsif Item'Length >= 5 and then Item (Item'First .. Item'First + 4) = "(Hang" then
               return Item;

            elsif Item (Item'First) = '(' then
               --  Anchored or Language-specific function
               return "(Simple, " & Item & ")";

            elsif Item = "nil" then
               return "(Simple, (Label => None))";

            else
               --  simple integer
               return "(Simple, (Int, " & Item & "))";
            end if;
         end Ensure_Indent_Param;

         Param_Label_Count : Ada.Containers.Count_Type := 0;

         procedure One_Param (Label : in String := "")
         is
            Pair : String_Pair_Type;
         begin
            if Label = "" then
               if RHS.Auto_Token_Labels then
                  Pair.Name := +Next_Token_Label;
               end if;
            else
               Pair.Name := +Label;
            end if;

            case Params (Last) is
            when '(' =>
               --  cons or function
               declare
                  Label_Last : constant Integer := Check_Cons;
               begin
                  if Label_Last > 0 then
                     --  cons; manual label
                     pragma Assert (not RHS.Auto_Token_Labels);
                     declare
                        Label : constant String := Params (Last + 1 .. Label_Last);
                     begin
                        Last := Index_Non_Blank (Params, Label_Last + 3);
                        One_Param (Label);
                     end;
                     Param_Label_Count := @ + 1;

                     if Params (Last) /= ')' then
                        Put_Error
                          (Error_Message
                             (Grammar_File_Name,
                              RHS.Source_Line, "invalid indent syntax; missing ')'"));
                     end if;
                     Last := Last + 1;
                  else
                     --  function
                     Pair.Value := +"(False, " & Ensure_Indent_Param (Expression (Last)) & ')';
                     Param_List.Append (Pair);
                  end if;
               end;

            when '[' =>
               --  vector
               Pair.Value := +"(True, " & Ensure_Indent_Param (Expression (Last + 1));
               Pair.Value := @ & ", " & Ensure_Indent_Param (Expression (Last + 1)) & ')';

               Param_List.Append (Pair);

               if Params (Last) /= ']' then
                  Put_Error
                    (Error_Message
                       (Grammar_File_Name, RHS.Source_Line, "indent missing ']'"));
               end if;
               Last := Last + 1;

            when others =>
               --  integer or symbol
               Pair.Value := +"(False, " & Ensure_Indent_Param (Expression (Last)) & ')';
               Param_List.Append (Pair);
            end case;
         end One_Param;

      begin
         loop
            if Params (Last) /= ']' then
               Last := Index_Non_Blank (Params, Last + 1);
               if Last = 0 then
                  Put_Error (Error_Message (Grammar_File_Name, RHS.Source_Line, "indent missing ']'"));
                  return -Result;
               end if;
            end if;

            exit when Params (Last) = ']';

            One_Param;
         end loop;

         --  Now we have Param_List; match it against RHS.Tokens and create Result.

         if RHS.Auto_Token_Labels or Param_Label_Count = Param_List.Length then
            --  All tokens are either manually or automatically labeled, and if
            --  manual then all parameters are manually labeled, and we can detect
            --  extra params in edited RHS.
            declare
               use String_Pair_Lists;
               use all type SAL.Base_Peek_Type;

               Token_I   : Positive_Index_Type      := RHS.Tokens.First_Index;
               Param_Cur : String_Pair_Lists.Cursor := Param_List.First;
               Param_I   : Positive_Index_Type      := RHS.Tokens.First_Index;

               Nil_Indent : constant String := "(False, (Simple, (Label => None)))";
            begin
               loop
                  exit when Token_I > RHS.Tokens.Last_Index or not Has_Element (Param_Cur);

                  declare
                     Token_Label : constant String := -RHS.Tokens (Token_I).Label;
                     Param_Label : constant String := -Element (Param_Cur).Name;
                  begin
                     if Token_Label = Param_Label then
                        Result := Result & (if Need_Comma then ", " else "") & Param_Label & " => " &
                          Element (Param_Cur).Value;

                        Mark_Label_Used (Token_Label);

                        Need_Comma := True;

                        Token_I := @ + 1;
                        Next (Param_Cur);
                        Param_I := @ + 1;

                     elsif RHS.Auto_Token_Labels and
                       (Token_Label'Length > 0 and then Token_Label (1) /= 'T') and
                       Token_I = Param_I
                     then
                        Result := Result & (if Need_Comma then ", " else "") & Token_Label & " => " & Nil_Indent;
                        Mark_Label_Used (Token_Label);
                        Need_Comma := True;

                        Token_I := @ + 1;
                        Next (Param_Cur);
                        Param_I := @ + 1;

                     else
                        Next (Param_Cur);
                        Param_I := @ + 1;
                     end if;
                  end;
               end loop;

               if (not RHS.Edited_Token_List or Prod_ID.RHS = 0) and then
                 (Token_I /= RHS.Tokens.Last_Index + 1 or Has_Element (Param_Cur))
               then
                  --  We don't check 'Has_Element (Param_Cur)' when edited_token_list
                  --  and RHS_Index /= 0, because we expect to have more params than
                  --  tokens. RHS_Index = 0 always has all optional tokens.
                  if RHS.Auto_Token_Labels then
                     Put_Error
                       (Error_Message
                          (Grammar_File_Name, RHS.Source_Line, Image (Prod_ID, Generate_Data.Descriptor.all)) &
                          (if Token_I <= RHS.Tokens.Last_Index then " missing" else " extra") & " indent parameters");
                  else
                     Put_Error
                       (Error_Message
                          (Grammar_File_Name, RHS.Source_Line, Image (Prod_ID, Generate_Data.Descriptor.all) &
                             ": missing or extra indent parameter, or missing token label"));
                  end if;
               end if;
            end;

         else
            --  No labels; assume Param_List is correct.
            for Pair of Param_List loop
               Result := Result & (if Need_Comma then ", " else "") & Pair.Value;
               Need_Comma := True;
            end loop;
         end if;

         Nonterm_Needed := True;
         if Param_List.Length = 1 then
            Result := Prefix & "1 => " & Result;
         else
            Result := Prefix & Result;
         end if;

         return -(Result & "))");
      end Indent_Params;

      function Merge_Names_Params (Params : in String) return String
      is
         --  Input looks like "1 2)"
         First             : constant Integer := Index_Non_Blank (Params);
         Second            : constant Integer := Index (Params, Blank_Set, First);
         Label_First       : constant String  := Get_Label (Params (First .. Second - 1));
         Label_Used_First  : constant Boolean := Label_Used (Label_First);
         Label_Second      : constant String  := Get_Label (Params (Second + 1 .. Params'Last - 1));
         Label_Used_Second : constant Boolean := Label_Used (Label_Second);
      begin
         Nonterm_Needed := True;

         if Label_Used_First and Label_Used_Second then
            return " (Tree, Nonterm, Tokens, " & Label_First & ", " & Label_Second & ")";

         elsif (not Label_Used_First) and Label_Used_Second then
            --  A copied EBNF RHS; see subprograms.wy Name
            return " (Tree, Nonterm, Tokens, " & Label_Second & ")";
         else
            Put_Error
              (Error_Message
                 (Grammar_File_Name, RHS.Source_Line, "merge_names token label error"));
            return " (Tree, Nonterm, Tokens)";
         end if;
      end Merge_Names_Params;

      function Match_Names_Params (Params : in String) return String
      is
         --  Input looks like: 1 2)
         First             : constant Integer := Index_Non_Blank (Params);
         Second            : constant Integer := Index (Params, Blank_Set, First);
         Label_First       : constant String  := Get_Label (Params (First .. Second - 1));
         Label_Second      : constant String  := Get_Label (Params (Second + 1 .. Params'Last - 1));
         Label_Used_First  : constant Boolean := Label_Used (Label_First);
         Label_Used_Second : constant Boolean := Label_Used (Label_Second);
      begin
         if Label_Used_First and Label_Used_Second then
            return " (Tree, Tokens, " &
              Label_First & ", " & Label_Second & ", " &
              (if Length (Input_Data.Language_Params.End_Names_Optional_Option) > 0
               then -Input_Data.Language_Params.End_Names_Optional_Option
               else "False") & ")";
         else
            return "";
         end if;
      end Match_Names_Params;

      function Language_Action_Params (Params : in String; Action_Name : in String) return String
      is
         --  Input looks like: [1 2 ...])
         Result      : Unbounded_String;
         Need_Comma  : Boolean := False;
         Param_Count : Integer := 0;
         First       : Integer;
         Last        : Integer := Params'First; --  '['
      begin
         loop
            First := Index_Non_Blank (Params, Last + 1);
            Last  := Index (Params, Space_Paren_Set, First);
            declare
               Label : constant String := Get_Label (Params (First .. Last - 1));
            begin
               if Label_Used (Label) then
                  Param_Count := Param_Count + 1;
                  if Need_Comma then
                     Result := Result & ", ";
                  else
                     Need_Comma := True;
                  end if;
                  Result := Result & Label;
               end if;
               exit when Params (Last) = ']';
               if Last = Params'Last then
                  Put_Error
                    (Error_Message
                       (Grammar_File_Name, RHS.Source_Line, Action_Name & " missing ']'"));
                  exit;
               end if;
            end;
         end loop;
         if Param_Count = 0 then
            return "";
         elsif Param_Count = 1 then
            return "(1 => " & (-Result) & ")";
         else
            return "(" & (-Result) & ")";
         end if;
      end Language_Action_Params;

      procedure Translate_Sexp (Line : in String)
      is
         Last       : constant Integer := Index (Line, Blank_Set);
         Elisp_Name : constant String  := Line (Line'First + 1 .. (if Last = 0 then Line'Last else Last) - 1);

         procedure Assert_Face_Empty
         is begin
            if Length (Face_Line) > 0 then
               Put_Error
                 (Error_Message
                    (Grammar_File_Name, RHS.Source_Line, "multiple face actions"));
            end if;
         end Assert_Face_Empty;

         procedure Assert_Indent_Empty
         is begin
            if Length (Indent_Action_Line) > 0 then
               Put_Error
                 (Error_Message
                    (Grammar_File_Name, RHS.Source_Line, "multiple indent actions"));
            end if;
         end Assert_Indent_Empty;

         procedure Assert_Check_Empty
         is begin
            if Length (Check_Line) > 0 then
               Put_Error
                 (Error_Message
                    (Grammar_File_Name, RHS.Source_Line, "multiple check actions"));
            end if;
         end Assert_Check_Empty;

      begin
         --  wisi action/check functions, in same order as typically used in
         --  .wy files; Navigate, Face, Indent, Check.
         if Elisp_Name = "wisi-statement-action" then
            declare
               Params : constant String := Statement_Params (Line (Last + 1 .. Line'Last));
            begin
               if Params'Length > 0 then
                  Navigate_Lines.Append (Elisp_Name_To_Ada (Elisp_Name, False, 5) & Params & ";");
               end if;
            end;

         elsif Elisp_Name = "wisi-name-action" then
            declare
               First : constant Integer := Index_Non_Blank (Line, Last + 1);
               Last  : constant Integer := Index (Line, Space_Paren_Set, First);
               Label : constant String  := Get_Label (Line (First .. Last - 1));
            begin
               if Label_Used (Label) then
                  Nonterm_Needed := True;
                  Navigate_Lines.Append
                    ("Name_Action (Parse_Data, Tree, Nonterm, " & Label & ");");
               end if;
            end;

         elsif Elisp_Name = "wisi-motion-action" then
            declare
               Params : constant String := Motion_Params (Line (Last + 1 .. Line'Last));
            begin
               if Params'Length > 0 then
                  Navigate_Lines.Append (Elisp_Name_To_Ada (Elisp_Name, False, Trim => 5) & Params & ";");
               end if;
            end;

         elsif Elisp_Name = "wisi-face-apply-action" then
            Assert_Face_Empty;
            declare
               Params : constant String := Face_Apply_Params (Line (Last + 1 .. Line'Last));
            begin
               if Params'Length > 0 then
                  Face_Line := +Elisp_Name_To_Ada (Elisp_Name, False, Trim => 5) & Params & ";";
               end if;
            end;

         elsif Elisp_Name = "wisi-face-apply-list-action" then
            Assert_Face_Empty;
            declare
               Params : constant String := Face_Apply_Params (Line (Last + 1 .. Line'Last));
            begin
               if Params'Length > 0 then
                  Face_Line := +Elisp_Name_To_Ada (Elisp_Name, False, Trim => 5) & Params & ";";
               end if;
            end;

         elsif Elisp_Name = "wisi-face-mark-action" then
            Assert_Face_Empty;
            declare
               Params : constant String := Face_Mark_Params (Line (Last + 1 .. Line'Last));
            begin
               if Params'Length > 0 then
                  Face_Line := +Elisp_Name_To_Ada (Elisp_Name, False, Trim => 5) & Params & ";";
               end if;
            end;

         elsif Elisp_Name = "wisi-face-remove-action" then
            Assert_Face_Empty;
            declare
               Params : constant String := Face_Remove_Params (Line (Last + 1 .. Line'Last));
            begin
               if Params'Length > 0 then
                  Face_Line := +Elisp_Name_To_Ada (Elisp_Name, False, Trim => 5) & Params & ";";
               end if;
            end;

         elsif Elisp_Name = "wisi-indent-action" then
            Assert_Indent_Empty;
            Indent_Action_Line := +"Indent_Action_0" & Indent_Params (Line (Last + 1 .. Line'Last)) & ";";

         elsif Elisp_Name = "wisi-indent-action*" then
            Assert_Indent_Empty;
            declare
               Temp : constant Integer := Index (Line, Blank_Set, Last + 1);
            begin
               Indent_Action_Line := +"Indent_Action_1" &
                 Indent_Params (Line (Temp + 1 .. Line'Last), Line (Last + 1 .. Temp - 1) & ", ") & ";";
            end;

         elsif Elisp_Name = "wisi-propagate-name" then
            declare
               Label : constant String := Get_Label (Line (Last + 1 .. Line'Last - 1));
            begin
               if Label_Used (Label) then
                  Assert_Check_Empty;
                  Nonterm_Needed := True;
                  Check_Line := +"return " & Elisp_Name_To_Ada (Elisp_Name, False, Trim => 5) &
                    " (Tree, Nonterm, Tokens, " & Label & ");";
               end if;
            end;

         elsif Elisp_Name = "wisi-merge-names" then
            Assert_Check_Empty;
            Check_Line := +"return " & Elisp_Name_To_Ada (Elisp_Name, False, Trim => 5) &
              Merge_Names_Params (Line (Last + 1 .. Line'Last)) & ";";

         elsif Elisp_Name = "wisi-match-names" then
            declare
               Params : constant String := Match_Names_Params (Line (Last + 1 .. Line'Last));
            begin
               if Params'Length > 0 then
                  Assert_Check_Empty;
                  Check_Line := +"return " & Elisp_Name_To_Ada (Elisp_Name, False, Trim => 5) &
                    Params & ";";
               end if;
            end;

         elsif Elisp_Name = "wisi-terminate-partial-parse" then
            Assert_Check_Empty;
            Nonterm_Needed := True;
            Check_Line := +"return Terminate_Partial_Parse (Tree, Partial_Parse_Active, Partial_Parse_Byte_Goal, " &
              "Recover_Active, Nonterm);";

         elsif Input_Data.Tokens.Actions.Contains (+Elisp_Name) then
            --  Language-specific post-parse action (used in wisitoken grammar
            --  mode for wisi-check-parens).
            --
            --  IMPROVEME: handle labels for token args. wisitoken-grammar declares
            --  wisi-check-parens, but uses BNF syntax, so no token labels are
            --  needed.
            declare
               Item   : String_Pair_Type renames Input_Data.Tokens.Actions.Constant_Reference (+Elisp_Name);
               Params : constant String := Language_Action_Params (Line (Last + 1 .. Line'Last), Elisp_Name);
               Code   : constant String := -Item.Value &
                 " (Wisi.Parse_Data_Type'Class (User_Data), Tree, Nonterm, " & Params & ");";
            begin
               Nonterm_Needed := True;

               if Params'Length > 0 then
                  if "navigate" = -Item.Name then
                     Navigate_Lines.Append (Code);

                  elsif "face" = -Item.Name then
                     Assert_Face_Empty;
                     Face_Line := +Code;

                  elsif "indent" = -Item.Name then
                     Assert_Indent_Empty;
                     Indent_Action_Line := +Code;

                  else
                     Put_Error
                       (Error_Message
                          (Grammar_File_Name, RHS.Source_Line, "unrecognized post-parse action: '" &
                             (-Item.Name) & "'"));
                  end if;

                  --  else skip
               end if;
            end;
         else
            Put_Error
              (Error_Message
                 (Grammar_File_Name, RHS.Source_Line, "unrecognized elisp action: '" &
                    Elisp_Name & "'"));
         end if;
      end Translate_Sexp;

      Subprogram_Started : Boolean := False;
   begin
      for Sexp of Sexps loop
         begin
            Translate_Sexp (Sexp);
         exception
         when E : Not_Found =>
            Put_Error
              (Error_Message
                 (Grammar_File_Name, RHS.Source_Line, Ada.Exceptions.Exception_Message (E)));
         end;
      end loop;

      if Check then
         --  In an in-parse check action
         if Length (Check_Line) = 0 then
            Empty := True; -- don't output a spec for this.

         else
            Empty              := False;
            Subprogram_Started := True;
            Indent_Line ("function " & Name);
            Indent_Line (" (Tree           : in     WisiToken.Syntax_Trees.Tree;");
            Indent_Line ("  Nonterm        : in out WisiToken.Syntax_Trees.Recover_Token;");
            Indent_Line ("  Tokens         : in     WisiToken.Syntax_Trees.Recover_Token_Array;");
            Indent_Line ("  Recover_Active : in     Boolean)");
            Indent_Line (" return WisiToken.Syntax_Trees.In_Parse_Actions.Status");
            declare
               Unref_Tree    : constant Boolean := 0 = Index (Check_Line, "Tree");
               Unref_Nonterm : constant Boolean := 0 = Index (Check_Line, "Nonterm");
               Unref_Tokens  : constant Boolean := 0 = Index (Check_Line, "Tokens");
               Unref_Recover : constant Boolean := 0 = Index (Check_Line, "Recover_Active");
               Need_Comma    : Boolean          := False;
            begin
               if Unref_Tree or Unref_Nonterm or Unref_Tokens or Unref_Recover or
                 (for some I of Label_Needed => I)
               then
                  Indent_Line ("is");

                  Indent := Indent + 3;
                  if Unref_Tree or Unref_Nonterm or Unref_Tokens or Unref_Recover then
                     Indent_Start ("pragma Unreferenced (");

                     if Unref_Tree then
                        Put ((if Need_Comma then ", " else "") & "Tree");
                        Need_Comma := True;
                     end if;
                     if Unref_Nonterm then
                        Put ((if Need_Comma then ", " else "") & "Nonterm");
                        Need_Comma := True;
                     end if;
                     if Unref_Tokens then
                        Put ((if Need_Comma then ", " else "") & "Tokens");
                        Need_Comma := True;
                     end if;
                     if Unref_Recover then
                        Put ((if Need_Comma then ", " else "") & "Recover_Active");
                        Need_Comma := True;
                     end if;
                     Put_Line (");");
                  end if;

                  for I in Label_Needed'Range loop
                     if Label_Needed (I) then
                        Indent_Line
                          (-Labels (I) & " : constant SAL.Peek_Type :=" &
                             SAL.Peek_Type'Image (Find_Token_Index (I)) & ";");
                     end if;
                  end loop;
                  Indent := Indent - 3;

                  Indent_Line ("begin");
               else
                  Indent_Line ("is begin");
               end if;
            end;
            Indent := Indent + 3;
            Indent_Line (-Check_Line);
         end if;
      else
         --  In an action
         Empty              := False;
         Subprogram_Started := True;
         Indent_Line ("procedure " & Name);
         Indent_Line ("  (User_Data : in out WisiToken.Syntax_Trees.User_Data_Type'Class;");
         Indent_Line ("   Tree      : in out WisiToken.Syntax_Trees.Tree;");
         Indent_Line ("   Nonterm   : in     WisiToken.Syntax_Trees.Valid_Node_Access)");
         Indent_Line ("is");

         Indent := Indent + 3;
         Indent_Line ("Parse_Data : Wisi.Parse_Data_Type renames Wisi.Parse_Data_Type (User_Data);");

         if not Nonterm_Needed then
            --  Language_Action may not use this
            Indent_Line ("pragma Unreferenced (Nonterm);");
         end if;

         for I in Label_Needed'Range loop
            if Label_Needed (I) then
               Indent_Line
                 (-Labels (I) & " : constant SAL.Peek_Type :=" &
                    SAL.Peek_Type'Image (Find_Token_Index (I)) & ";");
            end if;
         end loop;

         Indent := Indent - 3;
         Indent_Line ("begin");
         Indent := Indent + 3;

         Indent_Line ("case Parse_Data.Post_Parse_Action is");
         Indent_Line ("when Navigate =>");
         if Navigate_Lines.Length > 0 then
            Indent := Indent + 3;
            for Line of Navigate_Lines loop
               Indent_Wrap (Line);
            end loop;
            Indent := Indent - 3;
         else
            Indent_Line ("   null;");
         end if;

         Indent_Line ("when Face =>");
         if Length (Face_Line) > 0 then
            Indent := Indent + 3;
            Indent_Wrap (-Face_Line);
            Indent := Indent - 3;
         else
            Indent_Line ("   null;");
         end if;

         Indent_Line ("when Indent =>");
         if Length (Indent_Action_Line) > 0 then
            Indent := Indent + 3;
            Indent_Wrap (-Indent_Action_Line);
            Indent := Indent - 3;
         else
            Indent_Line ("   null;");
         end if;
         Indent_Line ("end case;");
      end if;

      if Subprogram_Started then
         Indent := Indent - 3;
         Indent_Line ("end " & Name & ";");
         New_Line;
      end if;

   end Create_Ada_Action;

   function Any_Motion_Actions return Boolean
   is begin
      for Rule of Input_Data.Tokens.Rules loop
         for RHS of Rule.Right_Hand_Sides loop
            for Sexp of Split_Sexp (-RHS.Action, Grammar_File_Name, RHS.Source_Line) loop
               declare
                  Last       : constant Integer := Ada.Strings.Fixed.Index (Sexp, Blank_Set);
                  Elisp_Name : constant String  := Sexp (Sexp'First + 1 .. Last - 1);
               begin
                  if Elisp_Name = "wisi-motion-action" then
                     return True;
                  end if;
               end;
            end loop;
         end loop;
      end loop;
      return False;
   end Any_Motion_Actions;

   procedure Create_Ada_Actions_Body
     (Action_Names : not null access WisiToken.Names_Array_Array;
      Check_Names  : not null access WisiToken.Names_Array_Array;
      Label_Count  : in              Ada.Containers.Count_Type;
      Package_Name : in              String)
   is
      use Ada.Strings.Unbounded;
      use Generate_Utils;
      use WisiToken.Generate;

      File_Name : constant String := Output_File_Name_Root &
        (case Common_Data.Interface_Kind is
         when Process => "_process_actions",
         when Module  => "_module_actions") &
        ".adb";

      Motion_Actions : constant Boolean := Any_Motion_Actions;

      Body_File : File_Type;

   begin
      Create (Body_File, Out_File, File_Name);
      Set_Output (Body_File);
      Indent := 1;
      Put_File_Header (Ada_Comment, Use_Tuple => True, Tuple => Tuple);
      Put_Raw_Code (Ada_Comment, Input_Data.Raw_Code (Copyright_License));
      New_Line;

      if Label_Count > 0 then
         Put_Line ("with SAL;");
      end if;

      Put_Line ("with Wisi; use Wisi;");
      if Input_Data.Language_Params.Use_Language_Runtime then
         declare
            Pkg : constant String :=
              (if -Input_Data.Language_Params.Language_Runtime_Name = ""
               then Default_Language_Runtime_Package
               else -Input_Data.Language_Params.Language_Runtime_Name);
         begin
            --  For language-specific names in actions, checks.
            Put_Line ("with " & Pkg & "; use " & Pkg & ";");
         end;
      end if;

      if Input_Data.Check_Count > 0 then
         Indent_Line ("with WisiToken.In_Parse_Actions; use WisiToken.In_Parse_Actions;"); -- Match_Names etc.
      end if;
      case Common_Data.Interface_Kind is
      when Process =>
         null;

      when Module =>
         Put_Line ("with Emacs_Module_Aux; use Emacs_Module_Aux;");
         Put_Line ("with Ada.Exceptions;");
         Put_Line ("with Ada.Strings.Unbounded;");
      end case;

      Put_Line ("package body " & Package_Name & " is");
      Indent := Indent + 3;
      New_Line;

      if Input_Data.Check_Count > 0 then
         Indent_Line ("use WisiToken.Syntax_Trees.In_Parse_Actions;");
      end if;
      if Motion_Actions then
         Indent_Line ("use all type Motion_Param_Array;");
      end if;
      New_Line;

      --  generate Action and Check subprograms.

      for Rule of Input_Data.Tokens.Rules loop
         --  No need for a Token_Cursor here, since we only need the
         --  nonterminals.
         declare
            LHS_ID    : constant WisiToken.Token_ID := Find_Token_ID (Generate_Data, -Rule.Left_Hand_Side);
            RHS_Index : Integer                     := 0; -- Semantic_Action defines RHS_Index as zero-origin
            Empty     : Boolean;
         begin
            for RHS of Rule.Right_Hand_Sides loop
               if Length (RHS.Action) > 0 then
                  declare
                     Name : constant String := Action_Names (LHS_ID)(RHS_Index).all;
                  begin
                     Create_Ada_Action (Name, RHS, (LHS_ID, RHS_Index), RHS.Action, Rule.Labels, Empty, Check => False);
                     if Empty then
                        Action_Names (LHS_ID)(RHS_Index) := null;
                     end if;
                  end;
               end if;

               if Length (RHS.Check) > 0 then
                  declare
                     Name  : constant String := Check_Names (LHS_ID)(RHS_Index).all;
                  begin
                     Create_Ada_Action (Name, RHS, (LHS_ID, RHS_Index), RHS.Check, Rule.Labels, Empty, Check => True);
                     if Empty then
                        Check_Names (LHS_ID)(RHS_Index) := null;
                     end if;
                  end;
               end if;
               RHS_Index := RHS_Index + 1;
            end loop;
         end;
      end loop;

      Put_Line ("end " & Package_Name & ";");
      Close (Body_File);

      Set_Output (Standard_Output);

   end Create_Ada_Actions_Body;

   procedure Create_Ada_Main_Body
     (Actions_Package_Name : in String;
      Main_Package_Name    : in String)
   is
      use WisiToken.Generate;
      use Generate_Utils;

      File_Name : constant String := To_Lower (Main_Package_Name) & ".adb";
      Body_File : File_Type;
   begin
      Create (Body_File, Out_File, File_Name);
      Set_Output (Body_File);
      Indent := 1;

      Put_File_Header (Ada_Comment, Use_Tuple => True, Tuple => Tuple);
      Put_Raw_Code (Ada_Comment, Input_Data.Raw_Code (Copyright_License));
      New_Line;

      case Common_Data.Lexer is
      when None | Tree_Sitter_Lexer =>
         null;

      when re2c_Lexer =>
         Put_Line ("with SAL;");
         Put_Line ("with WisiToken.Lexer.re2c;");
         Put_Line ("with " & Output_File_Name_Root & "_re2c_c;");

      end case;

      case Common_Data.Generate_Algorithm is
      when LR_Generate_Algorithm =>
         if not Input_Data.Language_Params.Error_Recover then
            Put_Line ("with WisiToken.Parse.LR;");
         end if;

      when Packrat_Proc =>
         Put_Line ("with WisiToken.Productions;");

      when Packrat_Gen =>
         Put_Line ("with WisiToken.Parse.Packrat.Parser;");

      when External | Tree_Sitter =>
         null;
      end case;

      Put_Line ("with " & Actions_Package_Name & "; use " & Actions_Package_Name & ";");

      Put_Line ("package body " & Main_Package_Name & " is");
      Indent := Indent + 3;
      New_Line;

      case Common_Data.Lexer is
      when None | Tree_Sitter_Lexer =>
         null;

      when re2c_Lexer =>
         Create_re2c_Lexer (Generate_Data, Output_File_Name_Root);
      end case;

      case Common_Data.Generate_Algorithm is
      when LR_Generate_Algorithm =>
         LR_Create_Create_Parse_Table (Input_Data, Common_Data, Generate_Data);
         Create_Create_Productions (Generate_Data);
         LR_Create_Create_Parser (Actions_Package_Name, Common_Data, Generate_Data);

      when Packrat_Gen =>
         WisiToken.BNF.Generate_Packrat (Packrat_Data, Generate_Data);
         Create_Create_Productions (Generate_Data);
         Packrat_Create_Create_Parser (Actions_Package_Name, Common_Data, Generate_Data, Packrat_Data);

      when Packrat_Proc =>
         Create_Create_Productions (Generate_Data);
         Packrat_Create_Create_Parser (Actions_Package_Name, Common_Data, Generate_Data, Packrat_Data);

      when External =>
         External_Create_Create_Grammar (Generate_Data);

      when Tree_Sitter =>
         null;
      end case;

      case Common_Data.Interface_Kind is
      when Process =>
         null;

      when Module =>
         Indent_Line ("Parser : LR_Parser.Instance;");
         New_Line;

         Indent_Line ("function Parse (Env : Emacs_Env_Access) return emacs_module_h.emacs_value");
         Indent_Line ("is begin");
         Indent := Indent + 3;
         Indent_Line ("WisiToken.Trace_Parse := To_Integer (Env, Symbol_Value (Env, Elisp_Symbols (Wisi_Debug_ID)));");
         Indent_Line ("Wisi_Cache_Max := To_Integer (Env, Symbol_Value (Env, Elisp_Symbols (Wisi_Cache_Max_ID)));");
         Indent_Line ("Parser.Reset;");
         Indent_Line ("Parser.Parse;");
         Indent_Line ("return Env.Qnil;");
         Indent := Indent - 3;
         Indent_Line ("exception");
         Indent_Line ("when E : WisiToken.Parse_Error | WisiToken.Syntax_Error =>");
         Indent_Line ("   return To_Emacs (Env, Ada.Exceptions.Exception_Message (E));");
         Indent_Line ("when E : others =>");
         Indent_Line ("   declare");
         Indent_Line ("      use Ada.Exceptions;");
         Indent_Line ("   begin");
         Indent_Line ("      return To_Emacs (Env, Exception_Name (E) & "": "" & Exception_Message (E));");
         Indent_Line ("   end;");
         Indent_Line ("end Parse;");
         New_Line;

         Indent_Line ("function Init (Env : Emacs_Env_Access) return Interfaces.C.int");
         Indent_Line ("is");
         Indent_Line ("   Lexer_Elisp_Symbols : Lexers.Elisp_Array_Emacs_Value;");
         Indent_Line ("begin");
         Indent_Line ("   " & Main_Package_Name & ".Env := Env;");
         Indent_Line ("   Emacs_Module_Aux.Init (Env);");
         Indent_Line ("   for I in Token_Symbols'Range loop");
         Indent_Line ("      Token_Symbols (I) := Intern_Soft (Env, Token_Images (I).all);");
         Indent_Line ("   end loop;");
         Indent_Line ("   for I in Elisp_Symbols'Range loop");
         Indent_Line ("      Elisp_Symbols (I) := Intern_Soft (Env, User_Names (I).all);");
         Indent_Line ("   end loop;");
         Indent_Line ("   for I in Elisp_Numbers'Range loop");
         Indent_Line ("      Elisp_Numbers (I) := Env.make_fixnum (Env, emacs_module_h.int64_t (I));");
         Indent_Line ("   end loop;");
         Indent_Line ("   for I in Lexer_Elisp_Symbols'Range loop");
         Indent_Line ("      Lexer_Elisp_Symbols (I) := Intern_Soft (Env, Lexers.Tokens (I).all);");
         Indent_Line ("   end loop;");
         Indent_Line ("   Parser := Create_Parser (Env, Lexer_Elisp_Symbols);");
         Indent_Line ("   return 0;");
         Indent_Line ("exception");
         Indent_Line ("when E : others =>");
         Indent_Line
           ("   Signal_Error (Env, " &
              "Ada.Exceptions.Exception_Name (E) & "": "" & Ada.Exceptions.Exception_Message (E), Env.Qnil);");
         Indent_Line ("   return 1;");
         Indent_Line ("end Init;");
         New_Line;
      end case;

      Put_Line ("end " & Main_Package_Name & ";");
      Close (Body_File);

      Set_Output (Standard_Output);

   end Create_Ada_Main_Body;

   procedure Create_Process_Elisp
   is
      use Generate_Utils;
      use WisiToken.Generate;

      File : File_Type;

      Paren_1_Done : Boolean := False;
   begin
      Create (File, Out_File, Output_File_Name_Root & "-process.el");
      Set_Output (File);
      Indent := 1;

      --  We can't use Put_File_Header here because it does not output the
      --  file name.
      Put_Line
        (";;; " & Output_File_Name_Root &
           "-process.el --- Generated parser support file  -*- buffer-read-only:t lexical-binding:t -*-");
      Put_Command_Line (Elisp_Comment & "  ", Use_Tuple => True, Tuple => Tuple);
      Put_Raw_Code (Elisp_Comment, Input_Data.Raw_Code (Copyright_License));
      New_Line;
      Put_Line ("(require 'wisi-process-parse)");
      New_Line;

      Indent_Line  ("(defconst " & Output_File_Name_Root & "-process-token-table");
      Indent_Start ("  [");
      Indent := Indent + 3;
      for Cursor in All_Tokens (Generate_Data).Iterate loop
         if Paren_1_Done then
            Indent_Line (Name (Generate_Data, Cursor));
         else
            Paren_1_Done := True;
            Put_Line (Name (Generate_Data, Cursor));
         end if;

      end loop;
      Indent_Line ("])");
      Indent := Indent - 3;
      New_Line;

      Output_Elisp_Common.Indent_Name_Table
        (Output_File_Name_Root, "process-face-table", Input_Data.Tokens.Faces);

      --  We need -repair-image for wisi-repair-error
      New_Line;
      Output_Elisp_Common.Indent_Repair_Image (Output_File_Name_Root, "process", Input_Data.Tokens);

      New_Line;
      Put_Line ("(provide '" & Output_File_Name_Root & "-process)");
      Set_Output (Standard_Output);
      Close (File);

   end Create_Process_Elisp;

   procedure Create_Module_Elisp
   is
      use Ada.Strings.Unbounded;
      use Generate_Utils;
      use WisiToken.Generate;

      Lower_Package_Name_Root : constant String := To_Lower (File_Name_To_Ada (Output_File_Name_Root));

      function To_ID_Image (Name : in Ada.Strings.Unbounded.Unbounded_String) return String
      is begin
         --  Ada 'Val is 0 origin; Token_ID is 1 origin
         return Token_ID'Image (-1 + Find_Token_ID (Generate_Data, -Name));
      end To_ID_Image;

      File : File_Type;
   begin
      Create (File, Out_File, Output_File_Name_Root & "-module.el");
      Set_Output (File);
      Indent := 1;

      Put_Line (";; generated by WisiToken Wisi from " & Grammar_File_Name);
      Put_Command_Line (";; ", Use_Tuple => True, Tuple => Tuple);
      Put_Line (";;");

      --  don't need the prologue here

      Put_Line ("(require 'wisi-parse-common)");
      New_Line;

      --  Lexer tables; also contain terminals for wisi-tokens
      Indent_Keyword_Table (Output_File_Name_Root, "elisp", Input_Data.Tokens.Keywords, To_String'Access);
      Indent_Keyword_Table (Output_File_Name_Root, "module", Input_Data.Tokens.Keywords, To_ID_Image'Access);
      Indent_Token_Table (Output_File_Name_Root, "elisp", Input_Data.Tokens.Tokens, To_String'Access);
      Indent_Token_Table (Output_File_Name_Root, "module", Input_Data.Tokens.Tokens, To_ID_Image'Access);

      --  non-terminals. We only need the ones that actually have
      --  actions, and thus will appear in a call to To_Emacs. But
      --  Token_Symbols must be indexed by Token_ID, so we declare
      --  all of them.
      Indent_Line ("(defconst " & Output_File_Name_Root & "-module-nonterms");
      Indent_Line (" '(");
      Indent := Indent + 3;
      Indent_Line (WisiToken_Accept_Name);
      for Rule of Input_Data.Tokens.Rules loop
         Indent_Line (-Rule.Left_Hand_Side);
      end loop;
      Indent_Line ("))");
      Indent := Indent - 3;
      New_Line;

      Indent_Line
        ("(cl-defstruct (" & Lower_Package_Name_Root &
           "-wisi-module-parser (:include wisi-parser)))");
      New_Line;
      Indent_Line ("(defun " & Lower_Package_Name_Root & "-wisi-module-parser-make (dll-name)");
      Indent_Line ("  (module-load dll-name)");
      Indent_Line ("  (make-" & Lower_Package_Name_Root & "-wisi-module-parser))");
      New_Line;

      Indent_Line ("(defvar " & Lower_Package_Name_Root & "-module-lexer nil)");
      Indent_Line
        ("(declare-function " &
           Lower_Package_Name_Root &
           "-wisi-module-parse """ &
           Lower_Package_Name_Root &
           "-wisi-module-parse.c"")");
      New_Line;

      Indent_Line
        ("(cl-defmethod wisi-parse-current ((parser " &
           Lower_Package_Name_Root &
           "-wisi-module-parser))");
      Indent := Indent + 2;
      Indent_Line ("(let* ((wisi-lexer " & Lower_Package_Name_Root & "-module-lexer)");
      Indent_Line ("       (result (" & Lower_Package_Name_Root & "-wisi-module-parse)))");
      --  Result is nil for no errors, a string for some error.
      --  Ada code has already added line:column, but not file name
      Indent_Line ("  (when result");
      Indent_Line ("    (signal 'wisi-parse-error (format ""%s:%s"" (buffer-name) result)))))");
      New_Line;
      Indent := Indent - 2;

      Indent_Line ("(provide '" & Output_File_Name_Root & "-module)");
      Set_Output (Standard_Output);
      Close (File);

   end Create_Module_Elisp;

   procedure Create_Module_Aux
   is
      use WisiToken.Generate;

      Package_Name_Root       : constant String := File_Name_To_Ada (Output_File_Name_Root);
      Lower_Package_Name_Root : constant String := To_Lower (Package_Name_Root);

      File : File_Type;
   begin
      Create (File, Out_File, Output_File_Name_Root & "_wisi_module_parse.gpr");
      Set_Output (File);
      Indent := 1;
      Put_Line ("-- generated by WisiToken Wisi from " & Grammar_File_Name);
      Put_Command_Line ("-- ", Use_Tuple => True, Tuple => Tuple);
      Indent_Line ("with ""wisi_module_parse_common"";");
      Indent_Line ("library project " & Package_Name_Root & "_Wisi_Module_Parse is");
      New_Line;
      Indent := Indent + 3;
      Indent_Line ("for Languages use (""Ada"");");
      Indent_Line ("for Source_Dirs use (""../.."", ""."");");
      New_Line;
      Indent_Line ("for Source_Files use");
      Indent_Line ("  (");
      Indent := Indent + 3;
      Indent_Line ("""emacs_module_aux.ads"",");
      Indent_Line ("""emacs_module_aux.adb"",");
      Indent_Line ("""emacs_module_h.ads"",");
      Indent_Line ("""fasttoken-lexer-wisi_elisp.adb"",");
      Indent_Line ("""fasttoken-lexer-wisi_elisp.ads"",");
      Indent_Line ("""" & Lower_Package_Name_Root & "_module.adb"",");
      Indent_Line ("""" & Lower_Package_Name_Root & "_module.ads""");
      Indent := Indent - 3;
      Indent_Line ("  );");
      New_Line;
      Indent_Line ("for Object_Dir use ""libobjsjlj"";");
      Indent_Line ("for Library_Name use """ & Lower_Package_Name_Root & "_wisi_module_parse"";");
      Indent_Line ("for Library_Dir use ""libsjlj"";");
      --  This library is linked with *_wisi_module_parse_wrapper.c to
      --  make a dynamic library
      Indent_Line ("for Library_Kind use ""static"";");
      New_Line;
      Indent_Line ("package Compiler is");
      Indent := Indent + 3;
      Indent_Line
        ("for Default_Switches (""Ada"") use Wisi_Module_Parse_Common.Compiler'Default_Switches (""Ada"");");

      --  Grammar files can get very large, so they need some special switches:
      --
      --  'Wisi_Module_Parse_Common.Compiler'Default_Switches' includes 'gnatn', but that hangs
      Indent_Line ("case Wisi_Module_Parse_Common.Build is");
      Indent_Line ("when ""Debug"" =>");
      Indent_Line ("   for Switches (""" & Lower_Package_Name_Root & "_module.adb"") use");
      Indent_Line ("     Wisi_Module_Parse_Common.Compiler.Common_Switches &");
      Indent_Line ("     Wisi_Module_Parse_Common.Compiler.Standard_Style &");
      Indent_Line ("     (""-O0"");");
      Indent_Line ("when ""Normal"" =>");
      Indent_Line ("   for Switches (""" & Lower_Package_Name_Root & "_module.adb"") use");
      Indent_Line ("     Wisi_Module_Parse_Common.Compiler.Common_Switches &");
      Indent_Line ("     Wisi_Module_Parse_Common.Compiler.Standard_Style &");
      Indent_Line ("     (""-O2"");");
      Indent_Line ("end case;");

      Indent := Indent - 3;
      Indent_Line ("end Compiler;");
      New_Line;
      Indent_Line ("package Builder is");
      Indent_Line
        ("   for Default_Switches (""Ada"") use Wisi_Module_Parse_Common.Builder'Default_Switches (""Ada"");");
      Indent_Line ("end Builder;");
      Indent := Indent - 3;
      New_Line;
      Indent_Line ("end " & Package_Name_Root & "_Wisi_Module_Parse;");
      Set_Output (Standard_Output);
      Close (File);

      Create (File, Out_File, Output_File_Name_Root & "_wisi_module_parse_agg.gpr");
      Set_Output (File);
      Indent := 1;
      Put_Line ("-- generated by WisiToken Wisi from " & Grammar_File_Name);
      Put_Command_Line ("-- ", Use_Tuple => True, Tuple => Tuple);
      Indent_Line ("aggregate project " & Package_Name_Root & "_Wisi_Module_Parse_Agg is");
      Indent_Line ("   for Project_Path use (external (""WISI_FASTTOKEN""));");
      Indent_Line ("   for Project_files use (""" & Lower_Package_Name_Root & "_wisi_module_parse.gpr"");");
      Indent_Line ("end " & Package_Name_Root & "_Wisi_Module_Parse_Agg;");
      Set_Output (Standard_Output);
      Close (File);

      Create (File, Out_File, Output_File_Name_Root & "_wisi_module_parse_wrapper.c");
      Set_Output (File);
      Indent := 1;
      Put_Line ("// generated by WisiToken Wisi from " & Grammar_File_Name);
      Put_Command_Line ("// ", Use_Tuple => True, Tuple => Tuple);
      Indent_Line ("//  This file is just a wrapper around the Ada code in");
      Indent_Line ("//  *_wisi_module_parse.adb; it is needed to call adainit.");
      Indent_Line ("#include <emacs_module.h>");
      Indent_Line ("int plugin_is_GPL_compatible;");
      Indent_Line ("extern void adainit(void);");
      Indent_Line ("extern int " & Lower_Package_Name_Root & "_wisi_module_parse_init (emacs_env *env);");
      Indent_Line ("/* Parse current buffer, using parser in current module. */");
      Indent_Line ("extern emacs_value " & Lower_Package_Name_Root & "_wisi_module_parse (emacs_env *env);");
      Indent_Line ("static emacs_value Fparse (emacs_env *env, int nargs, emacs_value args[])");
      Indent_Line ("{");
      Indent_Line ("  return " & Lower_Package_Name_Root & "_wisi_module_parse (env);");
      Indent_Line ("}");
      New_Line;
      Indent_Line ("int emacs_module_init (struct emacs_runtime *ert)");
      Indent_Line ("{");
      Indent_Line ("  emacs_env *env = ert->get_environment (ert);");
      Indent_Line
        ("  env->bind_function (env, """ & Lower_Package_Name_Root &
           "-wisi-module-parse"", env->make_function (env, 1, 1, Fparse));");
      Indent_Line ("  adainit();");
      Indent_Line ("  return " & Lower_Package_Name_Root & "_wisi_module_parse_init (env);");
      Indent_Line ("}");
      Set_Output (Standard_Output);
      Close (File);
   end Create_Module_Aux;

begin
   declare
      Actions_Package_Name : constant String := File_Name_To_Ada (Output_File_Name_Root) &
        (case Common_Data.Interface_Kind is
         when Process => "_Process_Actions",
         when Module  => "_Module_Actions");

      Main_Package_Name : constant String := File_Name_To_Ada (Output_File_Name_Root) &
        (case Common_Data.Interface_Kind is
         when Process => "_Process",
         when Module  => "_Module") &
        Gen_Alg_Name & "_Main";
   begin
      if Input_Data.Action_Count > 0 or Input_Data.Check_Count > 0 then
         --  We typically have no actions when just getting started with a new language.
         Create_Ada_Actions_Body
           (Generate_Data.Action_Names, Generate_Data.Check_Names, Input_Data.Label_Count, Actions_Package_Name);
      end if;

      Create_Ada_Actions_Spec
        (Output_File_Name => Output_File_Name_Root &
           (case Common_Data.Interface_Kind is
            when Process  => "_process_actions.ads",
            when Module   => "_module_actions.ads"),
         Package_Name     => Actions_Package_Name,
         Input_Data       => Input_Data,
         Common_Data      => Common_Data,
         Generate_Data    => Generate_Data);

      if Tuple.Gen_Alg = External then
         Create_External_Main_Spec (Main_Package_Name, Tuple, Input_Data);

         Create_Ada_Main_Body (Actions_Package_Name, Main_Package_Name);
      else
         Create_Ada_Main_Body (Actions_Package_Name, Main_Package_Name);

         Create_Ada_Main_Spec
           (Output_File_Name  => Output_File_Name_Root & "_" &
              To_Lower (Interface_Type'Image (Common_Data.Interface_Kind)) &
              To_Lower (Gen_Alg_Name) & "_main.ads",
            Main_Package_Name => Main_Package_Name,
            Common_Data       => Common_Data,
            Input_Data        => Input_Data);
      end if;
   end;

   case Common_Data.Interface_Kind is
   when Process =>
      Create_Process_Elisp;

   when Module =>
      Create_Module_Elisp;
      Create_Module_Aux;
   end case;
exception
when others =>
   Set_Output (Standard_Output);
   raise;
end WisiToken.BNF.Output_Ada_Emacs;
