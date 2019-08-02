--  Abstract :
--
--  See spec.
--
--  Copyright (C) 2017 - 2019 Free Software Foundation, Inc.
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
with Ada.Strings.Bounded;
with Ada.Text_IO;
with SAL;
with WisiToken.Semantic_Checks;
package body Wisi is
   use WisiToken;

   Navigate_Cache_Code  : constant String := "1";
   Face_Property_Code   : constant String := "2";
   Indent_Code          : constant String := "3";
   Lexer_Error_Code     : constant String := "4";
   Parser_Error_Code    : constant String := "5";
   Check_Error_Code     : constant String := "6";
   Recover_Code         : constant String := "7 ";
   End_Code             : constant String := "8";
   Name_Property_Code   : constant String := "9";
   Language_Action_Code : constant String := "10 ";

   Chars_Per_Int : constant Integer := Integer'Width;

   ----------
   --  body subprogram specs (as needed), alphabetical

   function Indent_Nil_P (Indent : in Indent_Type) return Boolean;

   function Max_Anchor_ID
     (Data       : in out Parse_Data_Type;
      First_Line : in     Line_Number_Type;
      Last_Line  : in     Line_Number_Type)
     return Integer;

   function Paren_In_Anchor_Line
     (Data         : in out Parse_Data_Type'Class;
      Anchor_Token : in     Augmented_Token;
      Offset       : in     Integer)
     return Integer;

   ----------
   --  body subprograms bodies, alphabetical

   function Image (Anchor_IDs : in Anchor_ID_Vectors.Vector) return String
   is
      use Ada.Strings.Unbounded;
      Result : Unbounded_String := +"(";
   begin
      for I in Anchor_IDs.First_Index .. Anchor_IDs.Last_Index loop
         Result := Result & Integer'Image (Anchor_IDs (I));
         if I /= Anchor_IDs.Last_Index then
            Result := Result & ", ";
         else
            Result := Result & ")";
         end if;
      end loop;
      return -Result;
   end Image;

   function Image (Indent : in Indent_Type) return String
   is begin
      case Indent.Label is
      when Not_Set =>
         return "(" & Indent_Label'Image (Indent.Label) & ")";

      when Int =>
         return "(" & Indent_Label'Image (Indent.Label) & Integer'Image (Indent.Int_Indent) & ")";

      when Anchor_Nil =>
         return "(" & Indent_Label'Image (Indent.Label) & ", " & Image (Indent.Anchor_Nil_IDs) & ", nil)";

      when Anchor_Int =>
         return "(" & Indent_Label'Image (Indent.Label) & ", " & Image (Indent.Anchor_Int_IDs) & ", " & Integer'Image
           (Indent.Anchor_Int_Indent) & ")";

      when Anchored =>
         return "(" & Indent_Label'Image (Indent.Label) & ", " & Integer'Image (Indent.Anchored_ID) & ", " &
           Integer'Image (Indent.Anchored_Delta) & ")";

      when Anchor_Anchored =>
         return "(" & Indent_Label'Image (Indent.Label) & ", " & Image (Indent.Anchor_Anchored_IDs) & Integer'Image
           (Indent.Anchor_Anchored_ID) & ", " & Integer'Image (Indent.Anchor_Anchored_Delta) & ")";
      end case;
   end Image;

   procedure Indent_Apply_Anchored
     (Delta_Indent : in     Simple_Delta_Type;
      Indent       : in out Indent_Type)
   with Pre => Delta_Indent.Label = Anchored
   is begin
      --  [2] wisi-elisp-parse--apply-anchored; add Delta_Indent to Indent

      case Indent.Label is
      when Not_Set =>
         Indent := (Anchored, Delta_Indent.Anchored_ID, Delta_Indent.Anchored_Delta);

      when Int =>
         if Delta_Indent.Anchored_Accumulate then
            Indent := (Anchored, Delta_Indent.Anchored_ID, Indent.Int_Indent + Delta_Indent.Anchored_Delta);
         end if;

      when Anchor_Nil =>
         Indent :=
           (Anchor_Anchored,
            Indent.Anchor_Nil_IDs,
            Delta_Indent.Anchored_ID,
            Delta_Indent.Anchored_Delta);

      when Anchor_Int =>
         if Delta_Indent.Anchored_Accumulate then
            Indent :=
              (Anchor_Anchored,
               Indent.Anchor_Int_IDs,
               Delta_Indent.Anchored_ID,
               Delta_Indent.Anchored_Delta + Indent.Anchor_Int_Indent);
         end if;

      when Anchored | Anchor_Anchored =>
         --  already anchored
         null;
      end case;
   end Indent_Apply_Anchored;

   procedure Indent_Apply_Int (Indent : in out Indent_Type; Offset : in Integer)
   is begin
      --  [2] wisi-elisp-parse--apply-int; add an Int indent to Indent
      case Indent.Label is
      when Not_Set =>
         Indent := (Int, Offset);

      when Int =>
         Indent.Int_Indent := Indent.Int_Indent + Offset;

      when Anchor_Nil         =>
         Indent :=
           (Label             => Anchor_Int,
            Anchor_Int_IDs    => Indent.Anchor_Nil_IDs,
            Anchor_Int_Indent => Offset);

      when Anchor_Int =>
         Indent.Anchor_Int_Indent := Indent.Anchor_Int_Indent + Offset;

      when Anchored | Anchor_Anchored =>
         null;
      end case;
   end Indent_Apply_Int;

   procedure Indent_Line
     (Data         : in out Parse_Data_Type;
      Line         : in     Line_Number_Type;
      Delta_Indent : in     Delta_Type)
   is
      --  See note in Indent_Anchored_2 for why we can't use renames here.
      Indent : Indent_Type := Data.Indents (Line);
   begin
      case Delta_Indent.Label is
      when Simple =>
         case Delta_Indent.Simple_Delta.Label is
         when None =>
            null;

         when Int =>
            Indent_Apply_Int (Indent, Delta_Indent.Simple_Delta.Int_Delta);

         when Anchored =>
            Indent_Apply_Anchored (Delta_Indent.Simple_Delta, Indent);
         end case;

      when Hanging =>
         if Delta_Indent.Hanging_Accumulate or Indent_Nil_P (Data.Indents (Line)) then
            if Line = Delta_Indent.Hanging_First_Line then
               --  Apply delta_1
               case Delta_Indent.Hanging_Delta_1.Label is
               when None =>
                  null;
               when Int =>
                  Indent_Apply_Int (Indent, Delta_Indent.Hanging_Delta_1.Int_Delta);
               when Anchored =>
                  Indent_Apply_Anchored (Delta_Indent.Hanging_Delta_1, Indent);
               end case;
            else
               if Delta_Indent.Hanging_Paren_State = Data.Line_Paren_State (Line) then
                  case Delta_Indent.Hanging_Delta_2.Label is
                  when None =>
                     null;
                  when Int =>
                     Indent_Apply_Int (Indent, Delta_Indent.Hanging_Delta_2.Int_Delta);
                  when Anchored =>
                     Indent_Apply_Anchored (Delta_Indent.Hanging_Delta_2, Indent);
                  end case;
               end if;
            end if;
         end if;
      end case;

      if Trace_Action > Extra then
         Ada.Text_IO.Put_Line (";; indent_line: " & Line_Number_Type'Image (Line) & " => " & Image (Indent));
      end if;

      Data.Indents.Replace_Element (Line, Indent);
   end Indent_Line;

   function Indent_Nil_P (Indent : in Indent_Type) return Boolean
   is begin
      return Indent.Label in Not_Set | Anchor_Nil;
   end Indent_Nil_P;

   function Max_Anchor_ID
     (Data       : in out Parse_Data_Type;
      First_Line : in     Line_Number_Type;
      Last_Line  : in     Line_Number_Type)
     return Integer
   is
      Result : Integer := First_Anchor_ID - 1;
   begin
      for Line in First_Line .. Last_Line loop
         declare
            Indent : Indent_Type renames Data.Indents (Line);
         begin
            case Indent.Label is
            when Not_Set | Int =>
               null;
            when Anchor_Nil =>
               Result := Integer'Max (Result, Indent.Anchor_Nil_IDs (Indent.Anchor_Nil_IDs.First_Index));
            when Anchor_Int =>
               Result := Integer'Max (Result, Indent.Anchor_Int_IDs (Indent.Anchor_Int_IDs.First_Index));
            when Anchored =>
               Result := Integer'Max (Result, Indent.Anchored_ID);
            when Anchor_Anchored =>
               Result := Integer'Max (Result, Indent.Anchor_Anchored_ID);
            end case;
         end;
      end loop;
      return Result;
   end Max_Anchor_ID;

   function Paren_In_Anchor_Line
     (Data         : in out Parse_Data_Type'Class;
      Anchor_Token : in     Augmented_Token;
      Offset       : in     Integer)
     return Integer
   is
      Left_Paren_ID  : Token_ID renames Data.Left_Paren_ID;
      Right_Paren_ID : Token_ID renames Data.Right_Paren_ID;

      I              : Base_Token_Index := Anchor_Token.First_Terminals_Index;
      Paren_Count    : Integer          := 0;
      Paren_Char_Pos : Buffer_Pos       := Invalid_Buffer_Pos;
      Text_Begin_Pos : Buffer_Pos       := Invalid_Buffer_Pos;
   begin
      --  [1] wisi-elisp-parse--paren-in-anchor-line. That uses elisp syntax-ppss; here
      --  we search Terminals.
      loop
         declare
            Tok : Augmented_Token renames Data.Terminals (I);
         begin
            if Tok.ID = Left_Paren_ID then
               Paren_Count := Paren_Count + 1;
               if Paren_Count = 1 then
                  Paren_Char_Pos := Tok.Char_Region.First;
               end if;

            elsif Tok.ID = Right_Paren_ID then
               Paren_Count := Paren_Count - 1;

            end if;

            if Tok.First then
               Text_Begin_Pos := Tok.Char_Region.First;
               exit;
            end if;
         end;
         I := I - 1;
      end loop;

      if Paren_Char_Pos /= Invalid_Buffer_Pos and Text_Begin_Pos /= Invalid_Buffer_Pos then
         return 1 + Offset + Integer (Paren_Char_Pos - Text_Begin_Pos);
      else
         return Offset;
      end if;
   end Paren_In_Anchor_Line;

   procedure Put (Cache : in Navigate_Cache_Type)
   is
      package Bounded is new Ada.Strings.Bounded.Generic_Bounded_Length (Max => 2 + 11 * Chars_Per_Int);
      use Bounded;

      Line : Bounded_String := To_Bounded_String ("[");

      procedure Append (Item : in Nil_Buffer_Pos)
      is begin
         if Item.Set then
            Append (Line, Buffer_Pos'Image (Item.Item));
         else
            Append (Line, " -1");
         end if;
      end Append;
   begin
      Append (Line, Navigate_Cache_Code);
      Append (Line, Buffer_Pos'Image (Cache.Pos));
      Append (Line, Token_ID'Image (Cache.Statement_ID));
      Append (Line, Token_ID'Image (Cache.ID));
      Append (Line, Integer'Image (Cache.Length));
      Append (Line, Integer'Image (Navigate_Class_Type'Pos (Cache.Class)));
      Append (Cache.Containing_Pos);
      Append (Cache.Prev_Pos);
      Append (Cache.Next_Pos);
      Append (Cache.End_Pos);
      Append (Line, ']');
      Ada.Text_IO.Put_Line (To_String (Line));
   end Put;

   procedure Put (Cache : in WisiToken.Buffer_Region)
   is begin
      Ada.Text_IO.Put_Line
        ("[" & Name_Property_Code & Buffer_Pos'Image (Cache.First) & Buffer_Pos'Image (Cache.Last) & "]");
   end Put;

   procedure Put (Cache : in Face_Cache_Type)
   is
      package Bounded is new Ada.Strings.Bounded.Generic_Bounded_Length (Max => 2 + 4 * Chars_Per_Int);
      use Bounded;

      Line : Bounded_String := To_Bounded_String ("[");
   begin
      if Cache.Face.Set then
         Append (Line, Face_Property_Code);
         Append (Line, Buffer_Pos'Image (Cache.Region.First));
         Append (Line, Buffer_Pos'Image (Cache.Region.Last));
         Append (Line, Integer'Image (Cache.Face.Item));
         Append (Line, ']');
         Ada.Text_IO.Put_Line (To_String (Line));
      end if;
   end Put;

   procedure Put (Line_Number : in Line_Number_Type; Item : in Indent_Type)
   is begin
      --  All Anchors must be resolved at this point, but not all lines have
      --  an indent computed. A negative indent is an error in either the
      --  grammar indent rules or the algorithms in this package.
      case Item.Label is
      when Not_Set =>
         --  Especially with partial parse, we have no idea what this indent should be.
         null;

      when Int =>
         declare
            --  We can easily get negative indents when there are syntax errors.
            Ind : constant Integer := Integer'Max (0, Item.Int_Indent);
         begin
            Ada.Text_IO.Put_Line
              ('[' & Indent_Code & Line_Number_Type'Image (Line_Number) & Integer'Image (Ind) & ']');
         end;

      when Anchor_Nil | Anchor_Int | Anchored | Anchor_Anchored =>
         raise SAL.Programmer_Error with "Indent item has non-int label: " & Indent_Label'Image (Item.Label);
      end case;
   end Put;

   procedure Put
     (Item                          : in Parse.LR.Configuration;
      Terminals                     : in Augmented_Token_Arrays.Vector;
      Descriptor                    : in WisiToken.Descriptor;
      Embedded_Quote_Escape_Doubled : in Boolean)
   is
      use Ada.Containers;
      use Ada.Strings.Unbounded;
      use Parse.LR;

      Line    : Unbounded_String := To_Unbounded_String ("[");
      Last_Op : Config_Op        := (Fast_Forward, WisiToken.Token_Index'Last);

   begin
      if Trace_Action > Detail then
         Ada.Text_IO.Put_Line (";; " & Parse.LR.Image (Item.Ops, Descriptor));
      end if;

      Append (Line, Recover_Code);
      if Item.Ops.Length = 0 then
         Append (Line, "]");

      else
         for I in Item.Ops.First_Index .. Item.Ops.Last_Index loop
            declare
               Op : Config_Op renames Item.Ops (I);
            begin
               case Op.Op is
               when Fast_Forward =>
                  if Last_Op.Op in Insert then
                     Append (Line, "][]]");
                  elsif Last_Op.Op in Delete then
                     Append (Line, "]]");
                  end if;

                  Last_Op := Op;

               when Undo_Reduce | Push_Back =>
                  null;

               when Insert =>
                  if Last_Op.Op = Fast_Forward then
                     Append (Line, "[");
                     Append (Line, Buffer_Pos'Image (Terminals (Op.Ins_Token_Index).Char_Region.First));
                     Append (Line, "[");

                  elsif Last_Op.Op = Delete then
                     Append (Line, "]][");
                     Append (Line, Buffer_Pos'Image (Terminals (Op.Ins_Token_Index).Char_Region.First));
                     Append (Line, "[");

                  else
                     --  Last_Op.Op = Insert
                     null;
                  end if;
                  Append (Line, Token_ID'Image (Op.Ins_ID));

                  Last_Op := Op;

               when Delete =>
                  declare
                     Skip : Boolean := False;
                  begin
                     if Last_Op.Op = Fast_Forward then
                        Append (Line, "[");
                        Append (Line, Buffer_Pos'Image (Terminals (Op.Del_Token_Index).Char_Region.First));
                        Append (Line, "[][");

                     elsif Last_Op.Op = Insert then
                        Append (Line, "][");

                     elsif Last_Op.Op = Delete then
                        if Embedded_Quote_Escape_Doubled and then
                          ((Last_Op.Del_ID = Descriptor.String_1_ID and Op.Del_ID = Descriptor.String_1_ID) or
                             (Last_Op.Del_ID = Descriptor.String_2_ID and Op.Del_ID = Descriptor.String_2_ID))
                        then
                           declare
                              Tok_1 : Augmented_Token renames Terminals (Last_Op.Del_Token_Index);
                              Tok_2 : Augmented_Token renames Terminals (Op.Del_Token_Index);
                           begin
                              if Tok_1.Char_Region.Last + 1 = Tok_2.Char_Region.First then
                                 --  Buffer text was '"""', lexer repair changed it to '""""'. The
                                 --  repaired text looks like a single string with an embedded quote.
                                 --  But here, it is two STRING_LITERAL tokens. Don't send the second
                                 --  delete to elisp. See test/ada_mode-recover_string_quote_1.adb
                                 Skip := True;
                              end if;
                           end;
                        end if;

                     end if;

                     if not Skip then
                        Append (Line, Token_ID'Image (Op.Del_ID));
                     end if;
                  end;
                  Last_Op := Op;
               end case;
            end;
         end loop;

         case Last_Op.Op is
         when Fast_Forward =>
            Append (Line, "]");

         when Undo_Reduce | Push_Back =>
            null;

         when Insert =>
            Append (Line, "][]]]");
         when Delete =>
            Append (Line, "]]]");
         end case;
      end if;
      Ada.Text_IO.Put_Line (To_String (Line));
   end Put;

   procedure Resolve_Anchors (Data : in out Parse_Data_Type)
   is
      Begin_Indent  : Integer renames Data.Begin_Indent;
      Anchor_Indent : array (First_Anchor_ID .. Data.Max_Anchor_ID) of Integer;
   begin
      if Trace_Action > Outline then
         Ada.Text_IO.New_Line;
         Ada.Text_IO.Put_Line (";; Begin_Indent: " & Integer'Image (Data.Begin_Indent));
         for I in Data.Indents.First_Index .. Data.Indents.Last_Index loop
            Ada.Text_IO.Put_Line (";; " & Line_Number_Type'Image (I) & ", " & Image (Data.Indents (I)));
         end loop;
         Ada.Text_IO.Put_Line (";; resolve anchors");
      end if;

      for I in Data.Indents.First_Index .. Data.Indents.Last_Index loop
         declare
            Indent : constant Indent_Type := Data.Indents (I);
         begin
            case Indent.Label is
            when Not_Set =>
               --  Indent not computed, therefore not output.
               null;

            when Int =>
               Data.Indents.Replace_Element (I, (Int, Indent.Int_Indent + Begin_Indent));

            when Anchor_Nil =>
               for I of Indent.Anchor_Nil_IDs loop
                  Anchor_Indent (I) := Begin_Indent;
               end loop;
               Data.Indents.Replace_Element (I, (Int, Begin_Indent));

            when Anchor_Int =>
               for I of Indent.Anchor_Int_IDs loop
                  Anchor_Indent (I) := Indent.Anchor_Int_Indent + Begin_Indent;
               end loop;
               Data.Indents.Replace_Element (I, (Int, Indent.Anchor_Int_Indent + Begin_Indent));

            when Anchored =>
               Data.Indents.Replace_Element
                 (I, (Int, Anchor_Indent (Indent.Anchored_ID) + Indent.Anchored_Delta));

            when Anchor_Anchored =>
               declare
                  Temp : constant Integer :=
                    Anchor_Indent (Indent.Anchor_Anchored_ID) + Indent.Anchor_Anchored_Delta;
               begin
                  for I of Indent.Anchor_Anchored_IDs loop
                     Anchor_Indent (I) := Temp;
                  end loop;
                  Data.Indents.Replace_Element (I, (Int, Temp));
               end;
            end case;
         end;
      end loop;
   end Resolve_Anchors;

   procedure Set_End
     (Data           : in out Parse_Data_Type;
      Containing_Pos : in     Buffer_Pos;
      End_Pos        : in     Buffer_Pos)
   is
      use Navigate_Cursor_Lists;
      I            : Cursor := Data.End_Positions.First;
      Delete_Cache : Boolean;
      Temp         : Cursor;
   begin
      loop
         exit when not Has_Element (I);
         declare
            Cache : Navigate_Cache_Type renames Data.Navigate_Caches (Element (I));
         begin
            if Cache.Pos in Containing_Pos .. End_Pos then
               Cache.End_Pos := (True, End_Pos);
               Delete_Cache := True;
            else
               Delete_Cache := False;
            end if;
         end;
         if Delete_Cache then
            Temp := Next (I);
            Delete (Data.End_Positions, I);

            I := Temp;
         else
            Next (I);
         end if;

      end loop;
   end Set_End;

   ----------
   --  public subprograms (declaration order)

   procedure Initialize
     (Data              : in out Parse_Data_Type;
      Descriptor        : access constant WisiToken.Descriptor;
      Source_File_Name  : in     String;
      Post_Parse_Action : in     Post_Parse_Action_Type;
      Begin_Line        : in     Line_Number_Type;
      End_Line          : in     Line_Number_Type;
      Begin_Indent      : in     Integer;
      Params            : in     String)
   is
      pragma Unreferenced (Params);
   begin
      Data.Line_Begin_Pos.Set_First_Last
        (First   => Begin_Line,
         Last    => End_Line);

      --  + 1 for data on line following last line; see Lexer_To_Augmented.
      Data.Line_Paren_State.Set_First_Last
        (First   => Begin_Line,
         Last    => End_Line + 1);

      Data.Descriptor        := Descriptor;
      Data.Source_File_Name  := +Source_File_Name;
      Data.Post_Parse_Action := Post_Parse_Action;

      case Post_Parse_Action is
      when Navigate | Face =>
         null;
      when Indent =>
         Data.Indents.Set_First_Last
           (First   => Begin_Line,
            Last    => End_Line);

         Data.Begin_Indent := Begin_Indent;
      end case;

      Data.Reset;
   exception
   when E : others =>
      raise SAL.Programmer_Error with "wisi.initialize: " & Ada.Exceptions.Exception_Name (E) & ": " &
        Ada.Exceptions.Exception_Message (E);
   end Initialize;

   overriding procedure Reset (Data : in out Parse_Data_Type)
   is begin
      Data.Terminals.Clear;
      Data.Leading_Non_Grammar.Clear;
      --  Data.Line_Begin_Pos  set in Initialize, overwritten in Lexer_To_Augmented
      --  Data.Line_Begin_Token  ""

      for S of Data.Line_Paren_State loop
         S := 0;
      end loop;
      Data.Current_Paren_State := 0;

      Data.Navigate_Caches.Finalize;
      Data.Navigate_Caches.Initialize;
      Data.End_Positions.Clear;

      Data.Name_Caches.Finalize;
      Data.Name_Caches.Initialize;

      Data.Face_Caches.Finalize;
      Data.Face_Caches.Initialize;

      for I in Data.Indents.First_Index .. Data.Indents.Last_Index loop
         Data.Indents.Replace_Element (I, (Label => Not_Set));
      end loop;
      Data.Max_Anchor_ID := First_Anchor_ID - 1;
   end Reset;

   function Source_File_Name (Data : in Parse_Data_Type) return String
   is begin
      return -Data.Source_File_Name;
   end Source_File_Name;

   function Post_Parse_Action (Data : in Parse_Data_Type) return Post_Parse_Action_Type
   is begin
      return Data.Post_Parse_Action;
   end Post_Parse_Action;

   overriding
   procedure Lexer_To_Augmented
     (Data  : in out          Parse_Data_Type;
      Token : in              Base_Token;
      Lexer : not null access WisiToken.Lexer.Instance'Class)
   is
      use all type Ada.Containers.Count_Type;
   begin
      if Lexer.First then
         Data.Line_Begin_Pos (Token.Line) := Token.Char_Region.First;

         if Token.Line > Data.Line_Begin_Pos.First_Index and then
           Data.Line_Begin_Pos (Token.Line - 1) = Invalid_Buffer_Pos
         then
            --  Previous token contains multiple lines; ie %code in wisitoken_grammar.wy
            declare
               First_Set_Line : Line_Number_Type;
            begin
               for Line in reverse Data.Line_Begin_Pos.First_Index .. Token.Line - 1 loop
                  if Data.Line_Begin_Pos (Line) /= Invalid_Buffer_Pos then
                     First_Set_Line := Line;
                     exit;
                  end if;
               end loop;
               for Line in First_Set_Line + 1 .. Token.Line - 1 loop
                  Data.Line_Begin_Pos (Line) := Data.Line_Begin_Pos (First_Set_Line); -- good enough
               end loop;
            end;
         end if;
      end if;

      if Token.ID < Data.Descriptor.First_Terminal then
         --  Non-grammar token

         if Token.ID = Data.Descriptor.New_Line_ID then
            Data.Line_Paren_State (Token.Line + 1) := Data.Current_Paren_State;
         end if;

         if Data.Terminals.Length = 0 then
            Data.Leading_Non_Grammar.Append ((Token with Lexer.First));
         else
            declare
               Containing_Token : Augmented_Token renames Data.Terminals (Data.Terminals.Last_Index);

               Trailing_Blank : constant Boolean :=
                 Token.ID = Data.Descriptor.New_Line_ID and
                 (Containing_Token.Non_Grammar.Length > 0 and then
                    Containing_Token.Non_Grammar
                      (Containing_Token.Non_Grammar.Last_Index).ID = Data.Descriptor.New_Line_ID);
            begin
               if Lexer.First and
                 (Token.ID in Data.First_Comment_ID .. Data.Last_Comment_ID or
                    Trailing_Blank)
               then
                  if Containing_Token.First_Trailing_Comment_Line = Invalid_Line_Number then
                     Containing_Token.First_Trailing_Comment_Line := Token.Line;
                  end if;
                  Containing_Token.Last_Trailing_Comment_Line  := Token.Line;
               end if;

               Containing_Token.Non_Grammar.Append ((Token with Lexer.First));
            end;
         end if;

      else
         --  grammar token
         declare
            Temp : constant Augmented_Token :=
              (Token.ID,
               Byte_Region                 => Token.Byte_Region,
               Line                        => Token.Line,
               Column                      => Token.Column,
               Char_Region                 => Token.Char_Region,
               Deleted                     => False,
               First                       => Lexer.First,
               Paren_State                 => Data.Current_Paren_State,
               First_Terminals_Index       => Data.Terminals.Last_Index + 1,
               Last_Terminals_Index        => Data.Terminals.Last_Index + 1,
               First_Indent_Line           => (if Lexer.First then Token.Line else Invalid_Line_Number),
               Last_Indent_Line            => (if Lexer.First then Token.Line else Invalid_Line_Number),
               First_Trailing_Comment_Line => Invalid_Line_Number, -- Set by Reduce
               Last_Trailing_Comment_Line  => Invalid_Line_Number,
               Non_Grammar                 => <>);
         begin
            if Token.ID = Data.Left_Paren_ID then
               Data.Current_Paren_State := Data.Current_Paren_State + 1;

            elsif Token.ID = Data.Right_Paren_ID then
               Data.Current_Paren_State := Data.Current_Paren_State - 1;
            end if;

            Data.Terminals.Append (Temp);
         end;
      end if;
   end Lexer_To_Augmented;

   overriding
   procedure Delete_Token
     (Data                : in out Parse_Data_Type;
      Deleted_Token_Index : in     WisiToken.Token_Index)
   is
      use all type Ada.Containers.Count_Type;
      Deleted_Token    : Augmented_Token renames Data.Terminals (Deleted_Token_Index);
      Prev_Token_Index : Base_Token_Index := Deleted_Token_Index - 1;
      Next_Token_Index : Base_Token_Index := Deleted_Token_Index + 1;
   begin
      if Deleted_Token.Deleted then
         --  This can happen if error recovery screws up.
         if WisiToken.Trace_Action > WisiToken.Detail then
            Ada.Text_IO.Put_Line (";; delete token again; ignored " & Image (Deleted_Token, Data.Descriptor.all));
         end if;
         return;
      end if;
      if WisiToken.Trace_Action > WisiToken.Detail then
         Ada.Text_IO.Put_Line (";; delete token " & Image (Deleted_Token, Data.Descriptor.all));
      end if;

      Deleted_Token.Deleted := True;

      if Deleted_Token.Non_Grammar.Length > 0 then
         --  Move Non_Grammar to previous non-deleted token

         loop
            exit when Prev_Token_Index = Base_Token_Index'First;
            exit when Data.Terminals (Prev_Token_Index).Deleted = False;
            Prev_Token_Index := Prev_Token_Index - 1;
         end loop;

         if Prev_Token_Index = Base_Token_Index'First then
            Deleted_Token.Non_Grammar (Deleted_Token.Non_Grammar.First_Index).First := Deleted_Token.First;
            Data.Leading_Non_Grammar.Append (Deleted_Token.Non_Grammar);
         else
            declare
               Prev_Token : Augmented_Token renames Data.Terminals (Prev_Token_Index);
            begin
               Prev_Token.Non_Grammar.Append (Deleted_Token.Non_Grammar);

               if Deleted_Token.First_Trailing_Comment_Line /= Invalid_Line_Number then
                  if Prev_Token.First_Trailing_Comment_Line = Invalid_Line_Number then
                     Prev_Token.First_Trailing_Comment_Line := Deleted_Token.First_Trailing_Comment_Line;
                  end if;
                  Prev_Token.Last_Trailing_Comment_Line  := Deleted_Token.Last_Trailing_Comment_Line;
               end if;
            end;
         end if;
      end if;

      --  Data.Terminals.Last_Index is Wisi_EOI; it is never deleted
      loop
         exit when Data.Terminals (Next_Token_Index).Deleted = False;
         Next_Token_Index := Next_Token_Index + 1;
         exit when Next_Token_Index = Data.Terminals.Last_Index;
      end loop;

      if Deleted_Token.First and
        (Next_Token_Index = Data.Terminals.Last_Index or else
           Data.Terminals (Next_Token_Index).Line > Deleted_Token.Line)
      then
         --  Deleted_Token.Line is now blank; add to previous token non
         --  grammar.
         if Prev_Token_Index > Base_Token_Index'First then
            declare
               Prev_Token : Augmented_Token renames Data.Terminals (Prev_Token_Index);
            begin
               if Prev_Token.First_Trailing_Comment_Line = Invalid_Line_Number then
                  Prev_Token.First_Trailing_Comment_Line := Deleted_Token.Line;
                  Prev_Token.Last_Trailing_Comment_Line  := Deleted_Token.Line;
               else
                  if Prev_Token.First_Trailing_Comment_Line > Deleted_Token.Line then
                     Prev_Token.First_Trailing_Comment_Line := Deleted_Token.Line;
                  end if;
                  if Prev_Token.Last_Trailing_Comment_Line < Deleted_Token.Line then
                     Prev_Token.Last_Trailing_Comment_Line := Deleted_Token.Line;
                  end if;
               end if;
            end;
         end if;
      end if;

      if Deleted_Token.First and Next_Token_Index < Data.Terminals.Last_Index then
         if not Data.Terminals (Next_Token_Index).First then
            declare
               Next_Token : Augmented_Token renames Data.Terminals (Next_Token_Index);
            begin
               Next_Token.First             := True;
               Next_Token.First_Indent_Line := Deleted_Token.First_Indent_Line;
               Next_Token.Last_Indent_Line  := Deleted_Token.Last_Indent_Line;
            end;
         end if;
      end if;
   end Delete_Token;

   overriding
   procedure Reduce
     (Data    : in out Parse_Data_Type;
      Tree    : in out Syntax_Trees.Tree'Class;
      Nonterm : in     Syntax_Trees.Valid_Node_Index;
      Tokens  : in     Syntax_Trees.Valid_Node_Index_Array)
   is
      Aug_Nonterm : constant Augmented_Token_Access := new Augmented_Token'
        (ID          => Tree.ID (Nonterm),
         Byte_Region => Tree.Byte_Region (Nonterm),
         others      => <>);

      Trailing_Comment_Done : Boolean := False;
   begin
      Tree.Set_Augmented (Nonterm, Base_Token_Class_Access (Aug_Nonterm));

      for I in reverse Tokens'Range loop
         --  'reverse' to find token containing trailing comments; last
         --  non-virtual and non-empty token.
         if Tree.Byte_Region (Tokens (I)) /= Null_Buffer_Region then
            --  Token not entirely virtual
            declare
               Aug_Token : constant Aug_Token_Ref := Get_Aug_Token (Data, Tree, Tokens (I));
            begin

               if Data.Post_Parse_Action = Indent then
                  if Aug_Token.First_Terminals_Index /= Augmented_Token_Arrays.No_Index then
                     Aug_Nonterm.First_Terminals_Index := Aug_Token.First_Terminals_Index;
                  end if;

                  if Aug_Nonterm.Last_Terminals_Index = Augmented_Token_Arrays.No_Index then
                     Aug_Nonterm.Last_Terminals_Index := Aug_Token.Last_Terminals_Index;
                  end if;

                  Aug_Nonterm.First := Aug_Nonterm.First or Aug_Token.First;

                  if Aug_Token.First_Indent_Line /= Invalid_Line_Number then
                     Aug_Nonterm.First_Indent_Line := Aug_Token.First_Indent_Line;
                  elsif Trailing_Comment_Done and Aug_Token.First_Trailing_Comment_Line /= Invalid_Line_Number then
                     Aug_Nonterm.First_Indent_Line := Aug_Token.First_Trailing_Comment_Line;
                  end if;

                  if Aug_Nonterm.Last_Indent_Line = Invalid_Line_Number then
                     if Trailing_Comment_Done and Aug_Token.Last_Trailing_Comment_Line /= Invalid_Line_Number then
                        Aug_Nonterm.Last_Indent_Line := Aug_Token.Last_Trailing_Comment_Line;
                     elsif Aug_Token.Last_Indent_Line /= Invalid_Line_Number then
                        Aug_Nonterm.Last_Indent_Line := Aug_Token.Last_Indent_Line;
                     end if;
                  end if;

                  if not Trailing_Comment_Done then
                     Aug_Nonterm.First_Trailing_Comment_Line := Aug_Token.First_Trailing_Comment_Line;
                     Aug_Nonterm.Last_Trailing_Comment_Line  := Aug_Token.Last_Trailing_Comment_Line;
                     Trailing_Comment_Done := True;
                  end if;

               end if; --  Compute_Indent

               if Aug_Token.Line /= Invalid_Line_Number then
                  Aug_Nonterm.Line   := Aug_Token.Line;
                  Aug_Nonterm.Column := Aug_Token.Column;
               end if;

               if Aug_Nonterm.Char_Region.First > Aug_Token.Char_Region.First then
                  Aug_Nonterm.Char_Region.First := Aug_Token.Char_Region.First;
               end if;

               if Aug_Nonterm.Char_Region.Last < Aug_Token.Char_Region.Last then
                  Aug_Nonterm.Char_Region.Last := Aug_Token.Char_Region.Last;
               end if;

               Aug_Nonterm.Paren_State := Aug_Token.Paren_State;
            end;
         end if; -- Aug_Token not virtual
      end loop;
   end Reduce;

   procedure Statement_Action
     (Data    : in out Parse_Data_Type;
      Tree    : in     Syntax_Trees.Tree;
      Nonterm : in     Syntax_Trees.Valid_Node_Index;
      Tokens  : in     Syntax_Trees.Valid_Node_Index_Array;
      Params  : in     Statement_Param_Array)
   is
      First_Item         : Boolean        := True;
      Start_Set          : Boolean        := False;
      Override_Start_Set : Boolean        := False;
      Containing_Pos     : Nil_Buffer_Pos := Nil; --  wisi first-keyword-pos
   begin
      for Pair of Params loop
         if not (Pair.Index in Tokens'Range) then
            declare
               Nonterm_Tok : constant Aug_Token_Ref := Get_Aug_Token (Data, Tree, Nonterm);
            begin
               raise Fatal_Error with Error_Message
                 (File_Name => -Data.Source_File_Name,
                  Line      => Nonterm_Tok.Line,
                  Column    => Nonterm_Tok.Column,
                  Message   => "wisi-statement-action: " & Trimmed_Image (Tree.Production_ID (Nonterm)) &
                    " token index" & SAL.Peek_Type'Image (Pair.Index) &
                    " not in tokens range (" & SAL.Peek_Type'Image (Tokens'First) & " .." &
                    SAL.Peek_Type'Image (Tokens'Last) & "); bad grammar action.");
            end;

         elsif Tree.Byte_Region (Tokens (Pair.Index)) /= Null_Buffer_Region then
            declare
               use all type WisiToken.Syntax_Trees.Node_Label;
               Token  : constant Aug_Token_Ref :=
                  (if Pair.Class = Statement_End and then
                    Tree.Label (Tokens (Pair.Index)) = WisiToken.Syntax_Trees.Nonterm
                  then Data.Terminals.Variable_Ref (Tree.Max_Terminal_Index (Tokens (Pair.Index)))
                  else Get_Aug_Token (Data, Tree, Tokens (Pair.Index)));

               Cache_Pos : constant Buffer_Pos         := Token.Char_Region.First;
               Cursor    : Navigate_Cache_Trees.Cursor := Navigate_Cache_Trees.Find
                 (Data.Navigate_Caches.Iterate, Cache_Pos,
                  Direction => Navigate_Cache_Trees.Unknown);
            begin
               if Navigate_Cache_Trees.Has_Element (Cursor) then
                  declare
                     Cache : Navigate_Cache_Type renames Data.Navigate_Caches (Cursor);
                  begin
                     if Pair.Class = Statement_Start then
                        if Start_Set then
                           Cache.Class := Motion;
                        else
                           Cache.Class := Statement_Start;
                           Start_Set   := True;
                        end if;
                     elsif Override_Start_Set then
                        Cache.Class := Statement_Start;
                        Start_Set   := True;
                     else
                        Cache.Class := Pair.Class;
                     end if;
                     Cache.Statement_ID   := Tree.ID (Nonterm);
                     Cache.Containing_Pos := Containing_Pos;
                  end;
               else
                  Cursor := Data.Navigate_Caches.Insert
                    ((Pos            => Cache_Pos,
                      Statement_ID   => Tree.ID (Nonterm),
                      ID             => Token.ID,
                      Length         => Length (Token.Char_Region),
                      Class          => (if Override_Start_Set then Statement_Start else Pair.Class),
                      Containing_Pos => Containing_Pos,
                      others         => Nil));
               end if;

               Data.End_Positions.Append (Cursor);

               if First_Item then
                  First_Item := False;
                  if Override_Start_Set or Pair.Class = Statement_Start then
                     Override_Start_Set := False;
                     Containing_Pos     := (True, Token.Char_Region.First);
                  end if;
               end if;

               if Pair.Class = Statement_End and Containing_Pos.Set then
                  Set_End (Data, Containing_Pos.Item, Cache_Pos);
               end if;
            end;

         else
            --  Token.Byte_Region is null
            if First_Item and Pair.Class = Statement_Start then
               Override_Start_Set := True;
            end if;
         end if;
      end loop;
   end Statement_Action;

   procedure Name_Action
     (Data    : in out Parse_Data_Type;
      Tree    : in     WisiToken.Syntax_Trees.Tree;
      Nonterm : in     Syntax_Trees.Valid_Node_Index;
      Tokens  : in     WisiToken.Syntax_Trees.Valid_Node_Index_Array;
      Name    : in     WisiToken.Positive_Index_Type)
   is
      use all type WisiToken.Syntax_Trees.Node_Label;
   begin
      if not (Name in Tokens'Range) then
         declare
            Token : constant Aug_Token_Ref := Get_Aug_Token (Data, Tree, Tokens (Tokens'First));
         begin
            raise Fatal_Error with Error_Message
              (File_Name => -Data.Source_File_Name,
               Line      => Token.Line,
               Column    => Token.Column,
               Message   => "wisi-name-action: " & Trimmed_Image (Tree.Production_ID (Nonterm)) & " name (" &
                 Trimmed_Image (Name) & ") not in Tokens range (" & SAL.Peek_Type'Image (Tokens'First) & " .." &
                    SAL.Peek_Type'Image (Tokens'Last) & "); bad grammar action.");
         end;
      end if;

      if Tree.Label (Tokens (Name)) = Syntax_Trees.Virtual_Terminal then
         return;
      end if;

      declare
         use Name_Cache_Trees;
         Name_Token : constant Aug_Token_Ref           := Get_Aug_Token (Data, Tree, Tokens (Name));
         Cursor     : constant Name_Cache_Trees.Cursor := Find
           (Data.Name_Caches.Iterate, Name_Token.Char_Region.First,
            Direction => Name_Cache_Trees.Unknown);
      begin
         if Name_Token.Char_Region = Null_Buffer_Region then
            return;
         elsif Has_Element (Cursor) then
            raise Fatal_Error with Error_Message
              (File_Name => -Data.Source_File_Name,
               Line      => Name_Token.Line,
               Column    => Name_Token.Column,
               Message   => "wisi-name-action: name set twice.");
         else
            Data.Name_Caches.Insert (Name_Token.Char_Region);
         end if;
      end;
   end Name_Action;

   procedure Containing_Action
     (Data       : in out Parse_Data_Type;
      Tree       : in     Syntax_Trees.Tree;
      Nonterm    : in     Syntax_Trees.Valid_Node_Index;
      Tokens     : in     Syntax_Trees.Valid_Node_Index_Array;
      Containing : in     Positive_Index_Type;
      Contained  : in     Positive_Index_Type)
   is
      use all type Syntax_Trees.Node_Label;
      pragma Unreferenced (Nonterm);

      --  [2] wisi-containing-action.
      --
      --  Compute as much as possible with virtual tokens; see
      --  test/format_paramlist.adb
   begin
      if Tree.Label (Tokens (Containing)) = Syntax_Trees.Virtual_Terminal or
        Tree.Label (Tokens (Contained)) = Syntax_Trees.Virtual_Terminal
      then
         return;
      end if;

      declare
         use Navigate_Cache_Trees;
         Containing_Tok    : constant Aug_Token_Ref := Get_Aug_Token (Data, Tree, Tokens (Containing));
         Containing_Region : Buffer_Region renames Containing_Tok.Char_Region;
         Contained_Tok     : constant Aug_Token_Ref := Get_Aug_Token (Data, Tree, Tokens (Contained));
         Contained_Region  : Buffer_Region renames Contained_Tok.Char_Region;
         Iterator          : constant Navigate_Cache_Trees.Iterator := Data.Navigate_Caches.Iterate;
         Cursor            : Navigate_Cache_Trees.Cursor;
         Mark              : constant Buffer_Pos                    := Containing_Region.First;
      begin
         if Containing_Region = Null_Buffer_Region then
            if Tree.Is_Virtual (Tokens (Containing)) then
               return;
            else
               raise Fatal_Error with Error_Message
                 (File_Name => -Data.Source_File_Name,
                  Line      => Containing_Tok.Line,
                  Column    => Containing_Tok.Column,
                  Message   => "wisi-containing-action: containing-region " &
                    Image (Containing_Tok.ID, Data.Descriptor.all) &
                    " is empty. grammar error; bad action.");
            end if;
         end if;

         if not Data.Navigate_Caches.Present (Containing_Region.First) then
            raise Fatal_Error with Error_Message
              (File_Name => -Data.Source_File_Name,
               Line      => Containing_Tok.Line,
               Column    => Containing_Tok.Column,
               Message   => "wisi-containing-action: containing token " &
                 Image (Containing_Tok.ID, Data.Descriptor.all) &
                 " has no cache. grammar error; missing action.");
         end if;

         if Contained_Tok.Char_Region /= Null_Buffer_Region then
            --  Contained region is nil in an empty production.
            Cursor := Previous (Iterator, Contained_Tok.Char_Region.Last);

            while Has_Element (Cursor) loop
               declare
                  Cache : Navigate_Cache_Type renames Variable_Ref (Data.Navigate_Caches, Cursor).Element.all;
               begin

                  exit when Cache.Pos < Contained_Region.First or
                    (Containing_Region.First = Contained_Region.First and
                       Cache.Pos <= Contained_Region.First);

                  --  Skip blocks that are already marked.

                  if Cache.Containing_Pos.Set then
                     Cursor := Find (Iterator, Cache.Containing_Pos.Item, Direction => Descending);
                  else
                     Cache.Containing_Pos := (True, Mark);
                     Cursor := Previous (Iterator, Cursor);
                  end if;

               end;
            end loop;
         end if;
      end;
   end Containing_Action;

   function "+" (Item : in Token_ID) return Token_ID_Lists.List
   is begin
      return Result : Token_ID_Lists.List do
         Result.Append (Item);
      end return;
   end "+";

   function "&" (List : in Token_ID_Lists.List; Item : in Token_ID) return Token_ID_Lists.List
   is begin
      return Result : Token_ID_Lists.List := List do
         Result.Append (Item);
      end return;
   end "&";

   function "&" (Left, Right : in Token_ID) return Token_ID_Lists.List
   is begin
      return Result : Token_ID_Lists.List do
         Result.Append (Left);
         Result.Append (Right);
      end return;
   end "&";

   procedure Motion_Action
     (Data    : in out Parse_Data_Type;
      Tree    : in     Syntax_Trees.Tree;
      Nonterm : in     Syntax_Trees.Valid_Node_Index;
      Tokens  : in     Syntax_Trees.Valid_Node_Index_Array;
      Params  : in     Motion_Param_Array)
   is
      --  [2] wisi-motion-action
      use Navigate_Cache_Trees;
      use all type Ada.Containers.Count_Type;

      Start             : Nil_Buffer_Pos := (Set => False);
      Prev_Keyword_Mark : Nil_Buffer_Pos := (Set => False);
      Iter              : constant Iterator := Data.Navigate_Caches.Iterate;
      Prev_Cache_Cur    : Cursor;
      Cache_Cur         : Cursor;
      Point             : Buffer_Pos;

      function Match (IDs : in Token_ID_Lists.List) return Boolean
      is
         Cache : Navigate_Cache_Type renames Constant_Ref (Data.Navigate_Caches, Cache_Cur).Element.all;
      begin
         --  [2] wisi-elisp-parse--match-token
         if (Start.Set and then Point = Start.Item) or else
           Cache.Containing_Pos = Start
         then
            for ID of IDs loop
               if ID = Cache.ID then
                  return True;
               end if;
            end loop;
         end if;
         return False;
      end Match;

   begin
      for Param of Params loop
         if Tree.Byte_Region (Tokens (Param.Index)) /= Null_Buffer_Region then
            declare
               Token  : constant Aug_Token_Ref := Get_Aug_Token (Data, Tree, Tokens (Param.Index));
               Region : constant Buffer_Region := Token.Char_Region;
            begin
               if not Start.Set then
                  Start := (True, Region.First);
               end if;

               Cache_Cur := Find (Iter, Region.First, Direction => Ascending);
               if not Has_Element (Cache_Cur) then
                  if Tree.Is_Virtual (Tokens (Param.Index)) then
                     return;
                  else
                     raise Fatal_Error with Error_Message
                       (File_Name => -Data.Source_File_Name,
                        Line      => Token.Line,
                        Column    => Token.Column,
                        Message   => "wisi-motion-action: token " &
                          WisiToken.Image (Token.ID, Data.Descriptor.all) &
                          " has no cache; add to statement-action for " &
                          Trimmed_Image (Tree.Production_ID (Nonterm)) & ".");
                  end if;
               end if;

               if Param.IDs.Length = 0 then
                  if Prev_Keyword_Mark.Set then
                     Variable_Ref (Data.Navigate_Caches, Cache_Cur).Element.Prev_Pos      := Prev_Keyword_Mark;
                     Variable_Ref (Data.Navigate_Caches, Prev_Cache_Cur).Element.Next_Pos := (True, Region.First);
                  end if;

                  Prev_Keyword_Mark := (True, Region.First);
                  Prev_Cache_Cur    := Cache_Cur;

               else
                  Point := Region.First;
                  loop
                     exit when Point >= Region.Last;
                     if Match (Param.IDs) then
                        if Prev_Keyword_Mark.Set then
                           if not Constant_Ref (Data.Navigate_Caches, Cache_Cur).Element.Prev_Pos.Set and
                             not Constant_Ref (Data.Navigate_Caches, Prev_Cache_Cur).Element.Next_Pos.Set
                           then
                              Variable_Ref (Data.Navigate_Caches, Cache_Cur).Element.Prev_Pos      := Prev_Keyword_Mark;
                              Variable_Ref (Data.Navigate_Caches, Prev_Cache_Cur).Element.Next_Pos := (True, Point);
                              Prev_Keyword_Mark := (True, Point);
                              Prev_Cache_Cur    := Cache_Cur;
                           end if;
                        else
                           Prev_Keyword_Mark := (True, Point);
                           Prev_Cache_Cur    := Cache_Cur;
                        end if;
                     end if;

                     Cache_Cur := Next (Iter, Cache_Cur);
                     exit when Cache_Cur = No_Element;

                     Point := Constant_Ref (Data.Navigate_Caches, Cache_Cur).Element.Pos;
                  end loop;
               end if;
            end;
         end if;
      end loop;
   end Motion_Action;

   procedure Face_Apply_Action
     (Data    : in out Parse_Data_Type;
      Tree    : in     Syntax_Trees.Tree;
      Nonterm : in     Syntax_Trees.Valid_Node_Index;
      Tokens  : in     Syntax_Trees.Valid_Node_Index_Array;
      Params  : in     Face_Apply_Param_Array)
   is
      pragma Unreferenced (Nonterm);

      --  [2] wisi-face-apply-action
      use Face_Cache_Trees;

      Iter       : constant Iterator := Data.Face_Caches.Iterate;
      Cache_Cur  : Cursor;
      Suffix_Cur : Cursor;
   begin
      for Param of Params loop
         if Tree.Byte_Region (Tokens (Param.Index)) /= Null_Buffer_Region then
            declare
               Token : constant Aug_Token_Ref := Get_Aug_Token (Data, Tree, Tokens (Param.Index));
            begin
               Cache_Cur := Find (Iter, Token.Char_Region.First, Direction => Ascending);
               if Has_Element (Cache_Cur) then
                  declare
                     Cache : Face_Cache_Type renames Variable_Ref (Data.Face_Caches, Cache_Cur).Element.all;
                  begin
                     case Cache.Class is
                     when Prefix =>
                        Cache.Face := (True, Param.Prefix_Face);

                        --  Check for suffix
                        Suffix_Cur := Next (Iter, Cache_Cur);
                        if Has_Element (Suffix_Cur) then
                           declare
                              Suf_Cache : Face_Cache_Type renames Variable_Ref
                                (Data.Face_Caches, Suffix_Cur).Element.all;
                           begin
                              if Suffix = Suf_Cache.Class and
                                Inside (Suf_Cache.Region.First, Token.Char_Region)
                              then
                                 Suf_Cache.Face := (True, Param.Suffix_Face);
                              end if;
                           end;
                        end if;

                     when Suffix =>
                        Cache.Face := (True, Param.Suffix_Face);
                     end case;
                  end;
               else
                  Data.Face_Caches.Insert ((Token.Char_Region, Suffix, (True, Param.Suffix_Face)));
               end if;
            end;
         end if;
      end loop;
   end Face_Apply_Action;

   procedure Face_Apply_List_Action
     (Data    : in out Parse_Data_Type;
      Tree    : in     Syntax_Trees.Tree;
      Nonterm : in     Syntax_Trees.Valid_Node_Index;
      Tokens  : in     Syntax_Trees.Valid_Node_Index_Array;
      Params  : in     Face_Apply_Param_Array)
   is
      pragma Unreferenced (Nonterm);

      --  [2] wisi-face-apply-list-action
      use Face_Cache_Trees;

      Iter      : constant Iterator := Data.Face_Caches.Iterate;
      Cache_Cur : Cursor;
   begin
      for Param of Params loop
         if Tree.Byte_Region (Tokens (Param.Index)) /= Null_Buffer_Region then
            declare
               Token : constant Aug_Token_Ref := Get_Aug_Token (Data, Tree, Tokens (Param.Index));
            begin
               Cache_Cur := Find_In_Range (Iter, Ascending, Token.Char_Region.First, Token.Char_Region.Last);
               loop
                  exit when not Has_Element (Cache_Cur) or else
                    Constant_Ref (Data.Face_Caches, Cache_Cur).Element.Region.First > Token.Char_Region.Last;
                  declare
                     Cache : Face_Cache_Type renames Variable_Ref (Data.Face_Caches, Cache_Cur).Element.all;
                  begin
                     case Cache.Class is
                     when Prefix =>
                        Cache.Face := (True, Param.Prefix_Face);

                     when Suffix =>
                        Cache.Face := (True, Param.Suffix_Face);
                     end case;
                  end;
                  Cache_Cur := Next (Iter, Cache_Cur);
               end loop;
            end;
         end if;
      end loop;
   end Face_Apply_List_Action;

   procedure Face_Mark_Action
     (Data    : in out Parse_Data_Type;
      Tree    : in     Syntax_Trees.Tree;
      Nonterm : in     Syntax_Trees.Valid_Node_Index;
      Tokens  : in     Syntax_Trees.Valid_Node_Index_Array;
      Params  : in     Face_Mark_Param_Array)
   is
      pragma Unreferenced (Nonterm);

      --  [2] wisi-face-apply-action
      use Face_Cache_Trees;

      Iter      : constant Iterator := Data.Face_Caches.Iterate;
      Cache_Cur : Cursor;
   begin
      for Param of Params loop
         if Tree.Byte_Region (Tokens (Param.Index)) /= Null_Buffer_Region then
            declare
               Token : constant Aug_Token_Ref := Get_Aug_Token (Data, Tree, Tokens (Param.Index));
            begin
               Cache_Cur := Find (Iter, Token.Char_Region.First, Direction => Ascending);
               if Has_Element (Cache_Cur) then
                  declare
                     Cache : Face_Cache_Type renames Variable_Ref (Data.Face_Caches, Cache_Cur).Element.all;
                     Other_Cur : Cursor := Find_In_Range
                       (Iter, Ascending, Cache.Region.Last + 1, Token.Char_Region.Last);
                     Temp : Cursor;
                  begin
                     loop
                        exit when not Has_Element (Other_Cur) or else
                          Constant_Ref (Data.Face_Caches, Other_Cur).Element.Region.First > Token.Char_Region.Last;
                        Temp := Other_Cur;
                        Other_Cur := Next (Iter, Other_Cur);
                        Delete (Data.Face_Caches, Temp);
                     end loop;

                     Cache.Class       := Param.Class;
                     Cache.Region.Last := Token.Char_Region.Last;
                  end;
               else
                  Data.Face_Caches.Insert ((Token.Char_Region, Param.Class, (Set => False)));
               end if;
            end;
         end if;
      end loop;
   end Face_Mark_Action;

   procedure Face_Remove_Action
     (Data    : in out Parse_Data_Type;
      Tree    : in     Syntax_Trees.Tree;
      Nonterm : in     Syntax_Trees.Valid_Node_Index;
      Tokens  : in     Syntax_Trees.Valid_Node_Index_Array;
      Params  : in     Face_Remove_Param_Array)
   is
      pragma Unreferenced (Nonterm);

      --  [2] wisi-face-remove-action
      use Face_Cache_Trees;

      Iter      : constant Iterator := Data.Face_Caches.Iterate;
      Cache_Cur : Cursor;
      Temp      : Cursor;
   begin
      for I of Params loop
         if Tree.Byte_Region (Tokens (I)) /= Null_Buffer_Region then
            declare
               Token : constant Aug_Token_Ref := Get_Aug_Token (Data, Tree, Tokens (I));
            begin
               Cache_Cur := Find_In_Range (Iter, Ascending, Token.Char_Region.First, Token.Char_Region.Last);
               loop
                  exit when not Has_Element (Cache_Cur) or else
                    Constant_Ref (Data.Face_Caches, Cache_Cur).Element.Region.First > Token.Char_Region.Last;
                  Temp := Cache_Cur;
                  Cache_Cur := Next (Iter, Cache_Cur);
                  Delete (Data.Face_Caches, Temp);
               end loop;
            end;
         end if;
      end loop;
   end Face_Remove_Action;

   function "+" (Item : in Integer) return Indent_Arg_Arrays.Vector
   is begin
      return Result : Indent_Arg_Arrays.Vector do
         Result.Append (Item);
      end return;
   end "+";

   function "&" (List : in Indent_Arg_Arrays.Vector; Item : in Integer) return Indent_Arg_Arrays.Vector
   is begin
      return Result : Indent_Arg_Arrays.Vector := List do
         Result.Append (Item);
      end return;
   end "&";

   function "&" (Left, Right : in Integer) return Indent_Arg_Arrays.Vector
   is begin
      return Result : Indent_Arg_Arrays.Vector do
         Result.Append (Left);
         Result.Append (Right);
      end return;
   end "&";

   function Image (Item : in Simple_Indent_Param) return String
   is begin
      return "(" & Simple_Indent_Param_Label'Image (Item.Label) &
        (case Item.Label is
         when None => "",
         when Int => Integer'Image (Item.Int_Delta),
         when Anchored_Label => Positive_Index_Type'Image (Item.Anchored_Index) & "," &
              Integer'Image (Item.Anchored_Delta),
         when Language => "<language_function>") & ")";
   end Image;

   function Image (Item : in Indent_Param) return String
   is begin
      return "(" & Indent_Param_Label'Image (Item.Label) & ", " &
        (case Item.Label is
         when Simple => Image (Item.Param),
         when Hanging_Label =>
            Image (Item.Hanging_Delta_1) & ", "  & Image (Item.Hanging_Delta_2) & ")");
   end Image;

   function Image (Item : in Indent_Pair) return String
   is begin
      return "(" & Image (Item.Code_Delta) &
        (if Item.Comment_Present
         then ", " & Image (Item.Comment_Delta)
         else "") & ")";
   end Image;

   procedure Indent_Action_0
     (Data    : in out Parse_Data_Type'Class;
      Tree    : in     Syntax_Trees.Tree;
      Nonterm : in     Syntax_Trees.Valid_Node_Index;
      Tokens  : in     Syntax_Trees.Valid_Node_Index_Array;
      Params  : in     Indent_Param_Array)
   is begin
      if Trace_Action > Outline then
         Ada.Text_IO.Put_Line (";; indent_action_0: " & Tree.Image (Nonterm, Data.Descriptor.all));
      end if;

      --  [2] wisi-indent-action
      for I in Tokens'Range loop
         if Tree.Byte_Region (Tokens (I)) /= Null_Buffer_Region and
           I in Params'Range -- in some translated EBNF, not every token has an indent param
         then
            declare
               use all type WisiToken.Syntax_Trees.Node_Index;
               use all type SAL.Base_Peek_Type;
               Tree_Token        : constant Syntax_Trees.Valid_Node_Index := Tokens (I);
               Token             : constant Aug_Token_Ref                 := Get_Aug_Token (Data, Tree, Tree_Token);
               Pair              : Indent_Pair renames Params (I);
               Code_Delta        : Delta_Type;
               Comment_Param     : Indent_Param;
               Comment_Param_Set : Boolean                                := False;
               Comment_Delta     : Delta_Type;
            begin
               if Trace_Action > Detail then
                  Ada.Text_IO.Put_Line
                    (";; indent_action_0 a: " & Tree.Image (Tree_Token, Data.Descriptor.all) & ": " & Image (Pair));
               end if;

               if Token.First_Indent_Line /= Invalid_Line_Number then
                  Code_Delta := Indent_Compute_Delta
                    (Data, Tree, Tokens, Pair.Code_Delta, Tree_Token, Indenting_Comment => False);

                  Indent_Token_1 (Data, Token, Code_Delta, Indenting_Comment => False);
               end if;

               if Token.First_Trailing_Comment_Line /= Invalid_Line_Number then
                  if Pair.Comment_Present then
                     Comment_Param     := Pair.Comment_Delta;
                     Comment_Param_Set := True;

                  elsif I < Tokens'Last then
                     Comment_Param     := Params (I + 1).Code_Delta;
                     Comment_Param_Set := True;

                  end if;

                  if Comment_Param_Set then
                     Comment_Delta := Indent_Compute_Delta
                       (Data, Tree, Tokens, Comment_Param, Tree_Token, Indenting_Comment => True);

                     Indent_Token_1 (Data, Token, Comment_Delta, Indenting_Comment => True);
                  end if;
               end if;
            end;
         end if;
      end loop;
   end Indent_Action_0;

   procedure Indent_Action_1
     (Data    : in out Parse_Data_Type'Class;
      Tree    : in     Syntax_Trees.Tree;
      Nonterm : in     Syntax_Trees.Valid_Node_Index;
      Tokens  : in     Syntax_Trees.Valid_Node_Index_Array;
      N       : in     Positive_Index_Type;
      Params  : in     Indent_Param_Array)
   is
      use all type Syntax_Trees.Node_Label;
   begin
      --  [2] wisi-indent-action*
      for I in Tokens'First .. N loop
         if Tree.Label (Tokens (I)) /= Virtual_Terminal and then
           Get_Aug_Token (Data, Tree, Tokens (I)).First
         then
            Indent_Action_0 (Data, Tree, Nonterm, Tokens, Params);
            return;
         end if;
      end loop;
   end Indent_Action_1;

   function Indent_Hanging_1
     (Data              : in out Parse_Data_Type;
      Tree              : in     Syntax_Trees.Tree;
      Tokens            : in     Syntax_Trees.Valid_Node_Index_Array;
      Tree_Indenting    : in     Syntax_Trees.Valid_Node_Index;
      Indenting_Comment : in     Boolean;
      Delta_1           : in     Simple_Indent_Param;
      Delta_2           : in     Simple_Indent_Param;
      Option            : in     Boolean;
      Accumulate        : in     Boolean)
     return Delta_Type
   is
      Indenting_Token : constant Aug_Token_Ref := Get_Aug_Token (Data, Tree, Tree_Indenting);
   begin
      --  [2] wisi-elisp-parse--hanging-1
      if Indenting_Comment then
         return Indent_Compute_Delta
           (Data, Tree, Tokens, (Simple, Delta_1), Tree_Indenting, Indenting_Comment);
      else
         return
           (Hanging,
            Hanging_First_Line  => Indenting_Token.Line,
            Hanging_Paren_State => Indenting_Token.Paren_State,
            Hanging_Delta_1     => Indent_Compute_Delta
              (Data, Tree, Tokens, (Simple, Delta_1), Tree_Indenting, Indenting_Comment).Simple_Delta,
            Hanging_Delta_2     =>
              (if (not Option) or
                 Indenting_Token.Line = Indenting_Token.First_Indent_Line -- first token in tok is first on line
               then Indent_Compute_Delta
                 (Data, Tree, Tokens, (Simple, Delta_2), Tree_Indenting, Indenting_Comment).Simple_Delta
               else Indent_Compute_Delta
                 (Data, Tree, Tokens, (Simple, Delta_1), Tree_Indenting, Indenting_Comment).Simple_Delta),
            Hanging_Accumulate => Accumulate);
      end if;
   end Indent_Hanging_1;

   procedure Put_Language_Action
     (Data    : in Parse_Data_Type;
      Content : in String)
   is
      pragma Unreferenced (Data);
   begin
      Ada.Text_IO.Put_Line ("[" & Language_Action_Code & Content & "]");
   end Put_Language_Action;

   procedure Put (Data : in out Parse_Data_Type; Parser : in Parse.Base_Parser'Class)
   is
      use all type Ada.Containers.Count_Type;

      Last_Term : constant Base_Token_Index := Parser.Tree.Max_Terminal_Index (Parser.Tree.Root);

      function Get_Last_Char_Pos return Buffer_Pos
      is begin
         if Parser.Terminals.Length = 0 then
            --  All comments, or empty
            if Data.Leading_Non_Grammar.Length > 0 then
               return Data.Leading_Non_Grammar (Data.Leading_Non_Grammar.Last_Index).Char_Region.Last;
            else
               return Buffer_Pos'First;
            end if;
         else
            if Last_Term = Invalid_Token_Index then
               --  All grammar tokens inserted by recover
               if Data.Leading_Non_Grammar.Length > 0 then
                  return Data.Leading_Non_Grammar (Data.Leading_Non_Grammar.Last_Index).Char_Region.Last;
               else
                  return Buffer_Pos'First;
               end if;
            else
               if Data.Terminals (Last_Term).Non_Grammar.Length > 0 then
                  return Data.Terminals (Last_Term).Non_Grammar
                    (Data.Terminals (Last_Term).Non_Grammar.Last_Index).Char_Region.Last;
               else
                  return Parser.Terminals (Last_Term).Char_Region.Last;
               end if;
            end if;
         end if;
      end Get_Last_Char_Pos;

      Last_Char_Pos : constant Buffer_Pos := Get_Last_Char_Pos;

      function Get_Last_Line return Line_Number_Type
      is begin
         for I in Data.Line_Begin_Pos.First_Index .. Data.Line_Begin_Pos.Last_Index loop
            if Data.Line_Begin_Pos (I) = Invalid_Buffer_Pos then
               raise SAL.Programmer_Error with "line_begin_pos" & Line_Number_Type'Image (I) & " invalid";
            end if;
            if Data.Line_Begin_Pos (I) > Last_Char_Pos then
               if I > Line_Number_Type'First then
                  return I - 1;
               else
                  return I;
               end if;
            end if;
         end loop;
         return Data.Line_Begin_Pos.Last_Index;
      end Get_Last_Line;

   begin
      if Trace_Action > Outline then
         Ada.Text_IO.Put_Line
           (";; last_char_pos:" & Buffer_Pos'Image (Last_Char_Pos + 1) &
              " last_line:" & Line_Number_Type'Image (Get_Last_Line));
      end if;

      --  +1 to match Emacs region
      Ada.Text_IO.Put_Line ('[' & End_Code & Buffer_Pos'Image (Last_Char_Pos + 1) & ']');

      case Data.Post_Parse_Action is
      when Navigate =>
         for Cache of Data.Navigate_Caches loop
            Put (Cache);
         end loop;
         for Cache of Data.Name_Caches loop
            Put (Cache);
         end loop;

      when Face =>
         for Cache of Data.Face_Caches loop
            Put (Cache);
         end loop;

      when Indent =>

         Resolve_Anchors (Data);

         if Trace_Action > Outline then
            Ada.Text_IO.Put_Line (";; indent leading non_grammar");
         end if;
         for Token of Data.Leading_Non_Grammar loop
            if Token.First then
               Put (Token.Line, (Int, Data.Begin_Indent));
            end if;
         end loop;

         --  It may be that not all lines in Data.Indents were parsed.
         if Trace_Action > Outline then
            Ada.Text_IO.Put_Line (";; indent grammar");
         end if;
         for I in Data.Indents.First_Index .. Get_Last_Line loop
            Put (I, Data.Indents (I));
         end loop;
      end case;
   end Put;

   procedure Put (Lexer_Errors : in Lexer.Error_Lists.List)
   is begin
      for Item of Lexer_Errors loop
         Ada.Text_IO.Put_Line
           ('[' & Lexer_Error_Code & Buffer_Pos'Image (Item.Char_Pos) &
              " ""lexer error" &
              (if Item.Recover_Char (1) = ASCII.NUL
               then """"
               elsif Item.Recover_Char (1) = '"'
               then """ ?\"""
               else """ ?" & Item.Recover_Char (1)) &
              "]");
         if Item.Recover_Char (2) /= ASCII.NUL then
            raise SAL.Programmer_Error with "lexer error with non-ascii or multiple repair char";
         end if;
      end loop;
   end Put;

   procedure Put
     (Data         : in Parse_Data_Type;
      Lexer_Errors : in Lexer.Error_Lists.List;
      Parse_Errors : in Parse.LR.Parse_Error_Lists.List;
      Tree         : in Syntax_Trees.Tree)
   is
      use all type SAL.Base_Peek_Type;
      use Ada.Text_IO;
      use Semantic_Checks;

      function Safe_Pos (Node : in Syntax_Trees.Valid_Node_Index) return Buffer_Pos
      is
         --  Return a reasonable position for the error at Node.
         --
         --  In a successful parse with error recovery, Node is a terminal with
         --  an augmented token in Data.Terminals, so that is the first
         --  choice.
         --
         --  If this is an error due to a bad recovery, Node may be a virtual
         --  token, with no position information, so we try to get information
         --  from its parent.
         use Syntax_Trees;

         N : Node_Index := Node;
      begin
         loop
            if Tree.Label (N) /= Virtual_Terminal then
               declare
                  Ref : constant Aug_Token_Ref := Get_Aug_Token (Data, Tree, N);
               begin
                  if Ref.Char_Region /= Null_Buffer_Region then
                     return Ref.Element.Char_Region.First;
                  end if;

               end;
            end if;
            N := Tree.Parent (N);
            exit when N = Invalid_Node_Index;
         end loop;
         return Buffer_Pos'First;
      end Safe_Pos;

      function Safe_Pos (Token : in Recover_Token) return Buffer_Pos
      is begin
         if Token.Name /= Null_Buffer_Region then
            return Token.Name.First;

         elsif Token.Byte_Region = Null_Buffer_Region then
            return Buffer_Pos'First;

         else
            return Token.Byte_Region.First;
         end if;
      end Safe_Pos;

   begin
      Put (Lexer_Errors);

      for Item of Parse_Errors loop
         --  We don't include parser id here; not very useful.
         case Item.Label is
         when Parse.LR.Action =>
            Put_Line
              ('[' & Parser_Error_Code & Buffer_Pos'Image (Safe_Pos (Item.Error_Token)) &
                 " ""syntax error: expecting " & Image (Item.Expecting, Data.Descriptor.all) &
                 ", found '" & Image (Tree.ID (Item.Error_Token), Data.Descriptor.all) & "'""]");

         when Parse.LR.Check =>
            Put_Line
              ('[' & Check_Error_Code & Integer'Image
                 (Semantic_Checks.Check_Status_Label'Pos (Item.Check_Status.Label)) &
                 (case Item.Check_Status.Label is
                  when Ok => "",
                  when Error =>
                     Buffer_Pos'Image (Safe_Pos (Item.Check_Status.Begin_Name)) &
                     Buffer_Pos'Image (Safe_Pos (Item.Check_Status.End_Name)) &
                       " ""block name error""]"));

         when Parse.LR.Message =>
            Put_Line
              ('[' & Parser_Error_Code & Buffer_Pos'Image (Buffer_Pos'First) &
                 " """ & (-Item.Msg) & """]");
         end case;

         if Item.Recover.Stack.Depth > 0 then
            Put (Item.Recover, Data.Terminals, Data.Descriptor.all, Data.Embedded_Quote_Escape_Doubled);
         end if;
      end loop;
   end Put;

   procedure Put_Error (Data : in Parse_Data_Type; Line_Number : in Line_Number_Type; Message : in String)
   is
      use Ada.Text_IO;
   begin
      Put_Line ("(error """ & Error_Message (-Data.Source_File_Name, Line_Number, 0, Message) & """)");
   end Put_Error;

   ----------
   --  Spec visible private subprograms, alphabetical

   function Image (Item : in Simple_Delta_Type) return String
   is begin
      return "(" & Simple_Delta_Labels'Image (Item.Label) &
        (case Item.Label is
         when None => "",
         when Int => Integer'Image (Item.Int_Delta),
         when Anchored => Integer'Image (Item.Anchored_ID) & Integer'Image (Item.Anchored_Delta) & " " &
              Boolean'Image (Item.Anchored_Accumulate))
        & ")";
   end Image;

   function Image (Item : in Delta_Type) return String
   is begin
      return "(" & Delta_Labels'Image (Item.Label) &
        (case Item.Label is
         when Simple => " " & Image (Item.Simple_Delta),
         when Hanging => Line_Number_Type'Image (Item.Hanging_First_Line) & Integer'Image (Item.Hanging_Paren_State) &
              " " & Image (Item.Hanging_Delta_1) & " " & Image (Item.Hanging_Delta_2) & " " &
              Boolean'Image (Item.Hanging_Accumulate)) & ")";
   end Image;

   function Current_Indent_Offset
     (Data         : in Parse_Data_Type;
      Anchor_Token : in Augmented_Token'Class;
      Offset       : in Integer)
     return Integer
   is begin
      return Offset + Integer (Anchor_Token.Char_Region.First - Data.Line_Begin_Pos (Anchor_Token.Line));
   end Current_Indent_Offset;

   function Find
     (Data  : in Parse_Data_Type;
      ID    : in Token_ID;
      Token : in Augmented_Token'Class)
     return Base_Token_Index
   is begin
      --  linear search for ID.
      for I in Token.First_Terminals_Index .. Token.Last_Terminals_Index loop
         if Data.Terminals (I).ID = ID then
            return I;
         end if;
      end loop;
      return Augmented_Token_Arrays.No_Index;
   end Find;

   function First_Line
     (Token             : in Augmented_Token;
      Indenting_Comment : in Boolean)
     return Line_Number_Type
   is begin
      return
        (if Indenting_Comment then
           (if Token.First_Trailing_Comment_Line = Invalid_Line_Number
            then Token.Line
            else Token.First_Trailing_Comment_Line)
         else
           (if Token.First_Indent_Line = Invalid_Line_Number
            then Token.Line
            else Token.First_Indent_Line));
   end First_Line;

   function Get_Aug_Token
     (Data       : in Parse_Data_Type'Class;
      Tree       : in Syntax_Trees.Tree'Class;
      Tree_Index : in Syntax_Trees.Valid_Node_Index)
     return Aug_Token_Ref
   is
      use all type Syntax_Trees.Node_Label;
   begin
      return
        (case Tree.Label (Tree_Index) is
         when Shared_Terminal => Data.Terminals.Variable_Ref (Tree.Terminal (Tree_Index)),
         when Virtual_Terminal => raise SAL.Programmer_Error with "wisi_runtime.get_aug_token virtual terminal",
         when Virtual_Identifier => raise SAL.Programmer_Error with "wisi_runtime.get_aug_token virtual identifier",
         when Nonterm => (Element => Augmented_Token_Access (Tree.Augmented (Tree_Index))));
   end Get_Aug_Token;

   overriding
   function Image
     (Item       : in Augmented_Token;
      Descriptor : in WisiToken.Descriptor)
     return String
   is
      ID_Image : constant String := Image (Item.ID, Descriptor);
   begin
      if Item.Line /= Invalid_Line_Number and Trace_Action <= Detail then
         return "(" & ID_Image &
           Line_Number_Type'Image (Item.Line) & ":" & Trimmed_Image (Integer (Item.Column)) & ")";

      elsif Item.Char_Region = Null_Buffer_Region then
         return "(" & ID_Image & ")";

      else
         return "(" & ID_Image & ", " & Image (Item.Char_Region) & ")";
      end if;
   end Image;

   function Image
     (Item       : in Augmented_Token_Access_Array;
      Descriptor : in WisiToken.Descriptor)
     return String
   is
      use all type SAL.Base_Peek_Type;
      use Ada.Strings.Unbounded;
      Result : Unbounded_String := +"(";
   begin
      for I in Item'Range loop
         Result := Result & Image (Item (I).all, Descriptor);
         if I /= Item'Last then
            Result := Result & ", ";
         end if;
      end loop;
      Result := Result & ")";
      return -Result;
   end Image;

   function Indent_Anchored_2
     (Data        : in out Parse_Data_Type;
      Anchor_Line : in     Line_Number_Type;
      Last_Line   : in     Line_Number_Type;
      Offset      : in     Integer;
      Accumulate  : in     Boolean)
     return Delta_Type
   is
      --  [2] wisi-elisp-parse--anchored-2; return an anchored delta
      use Anchor_ID_Vectors;
      --  We can't use a Reference here, because the Element in reference
      --  types is constrained (as are all allocated objects of access
      --  types; AARM 4.8 (6/3)), and we may need to change the Label.
      Indent    : Indent_Type      := Data.Indents (Anchor_Line);
      Anchor_ID : constant Integer := 1 + Max_Anchor_ID (Data, Anchor_Line, Last_Line);
   begin
      Data.Max_Anchor_ID := Integer'Max (Data.Max_Anchor_ID, Anchor_ID);

      case Indent.Label is
      when Not_Set =>
         Indent := (Anchor_Nil, To_Vector (Anchor_ID, 1));

         if Trace_Action > Extra then
            Ada.Text_IO.Put_Line
              (";; indent_anchored: " & Line_Number_Type'Image (Anchor_Line) & " => " & Image (Indent));
         end if;

      when Int =>
         Indent := (Anchor_Int, To_Vector (Anchor_ID, 1), Indent.Int_Indent);

         if Trace_Action > Extra then
            Ada.Text_IO.Put_Line
              (";; indent_anchored: " & Line_Number_Type'Image (Anchor_Line) & " => " & Image (Indent));
         end if;

      when Anchor_Nil =>
         Indent.Anchor_Nil_IDs := Anchor_ID & Indent.Anchor_Nil_IDs;

      when Anchor_Int =>
         Indent.Anchor_Int_IDs := Anchor_ID & Indent.Anchor_Int_IDs;

      when Anchored =>
         Indent := (Anchor_Anchored, To_Vector (Anchor_ID, 1), Indent.Anchored_ID, Indent.Anchored_Delta);

      when Anchor_Anchored =>
         Indent.Anchor_Anchored_IDs := Anchor_ID & Indent.Anchor_Anchored_IDs;
      end case;

      Data.Indents.Replace_Element (Anchor_Line, Indent);

      return (Simple, (Anchored, Anchor_ID, Offset, Accumulate));
   end Indent_Anchored_2;

   function Indent_Compute_Delta
     (Data              : in out Parse_Data_Type'Class;
      Tree              : in     Syntax_Trees.Tree;
      Tokens            : in     Syntax_Trees.Valid_Node_Index_Array;
      Param             : in     Indent_Param;
      Tree_Indenting    : in     Syntax_Trees.Valid_Node_Index;
      Indenting_Comment : in     Boolean)
     return Delta_Type
   is
      Indenting_Token : constant Aug_Token_Ref := Get_Aug_Token (Data, Tree, Tree_Indenting);
   begin
      --  [2] wisi-elisp-parse--indent-compute-delta, which evals wisi-anchored*, wisi-hanging*.
      case Param.Label is
      when Simple =>
         case Param.Param.Label is
         when None =>
            return (Simple, (Label => None));

         when Int =>
            return (Simple, (Int, Param.Param.Int_Delta));

         when Anchored_Label =>
            if Indenting_Token.Byte_Region = Null_Buffer_Region or
              Tree.Byte_Region (Tokens (Param.Param.Anchored_Index)) = Null_Buffer_Region
            then
               --  One of these is an entirely virtual token
               return Null_Delta;
            else
               declare
                  Anchor_Token : constant Aug_Token_Ref := Get_Aug_Token
                    (Data, Tree, Tokens (Param.Param.Anchored_Index));
               begin
                  case Anchored_Label'(Param.Param.Label) is
                  when Anchored_0 =>
                     --  [2] wisi-anchored, wisi-anchored-1
                     return Indent_Anchored_2
                       (Data,
                        Anchor_Line => Anchor_Token.Line,
                        Last_Line   => Indenting_Token.Last_Line (Indenting_Comment),
                        Offset      => Current_Indent_Offset (Data, Anchor_Token, Param.Param.Anchored_Delta),
                        Accumulate  => True);

                  when Anchored_1 =>
                     --  [2] wisi-anchored%
                     return Indent_Anchored_2
                       (Data,
                        Anchor_Line => Anchor_Token.Line,
                        Last_Line   => Indenting_Token.Last_Line (Indenting_Comment),
                        Offset      => Paren_In_Anchor_Line (Data, Anchor_Token, Param.Param.Anchored_Delta),
                        Accumulate  => True);

                  when Anchored_2 =>
                     --  [2] wisi-anchored%-
                     return Indent_Anchored_2
                       (Data,
                        Anchor_Line => Anchor_Token.Line,
                        Last_Line   => Indenting_Token.Last_Line (Indenting_Comment),
                        Offset      => Paren_In_Anchor_Line (Data, Anchor_Token, Param.Param.Anchored_Delta),
                        Accumulate  => False);

                  when Anchored_3 =>
                     --  [2] wisi-anchored*
                     if Indenting_Token.First then
                        return Indent_Anchored_2
                          (Data,
                           Anchor_Line => Anchor_Token.Line,
                           Last_Line   => Indenting_Token.Last_Line (Indenting_Comment),
                           Offset      => Current_Indent_Offset (Data, Anchor_Token, Param.Param.Anchored_Delta),
                           Accumulate  => True);

                     else
                        return Null_Delta;
                     end if;

                  when Anchored_4 =>
                     --  [2] wisi-anchored*-
                     return Indent_Anchored_2
                       (Data,
                        Anchor_Line => Anchor_Token.Line,
                        Last_Line   => Indenting_Token.Last_Line (Indenting_Comment),
                        Offset      => Current_Indent_Offset (Data, Anchor_Token, Param.Param.Anchored_Delta),
                        Accumulate  => False);

                  end case;
               end;
            end if;

         when Language =>
            return Param.Param.Function_Ptr
              (Data, Tree, Tokens, Tree_Indenting, Indenting_Comment, Param.Param.Args);
         end case;

      when Hanging_Label =>
         case Hanging_Label'(Param.Label) is
         when Hanging_0 => -- wisi-hanging
            return Indent_Hanging_1
              (Data, Tree, Tokens, Tree_Indenting, Indenting_Comment, Param.Hanging_Delta_1,
               Param.Hanging_Delta_2,
               Option => False, Accumulate => True);
         when Hanging_1 => -- wisi-hanging-
            return Indent_Hanging_1
              (Data, Tree, Tokens, Tree_Indenting, Indenting_Comment, Param.Hanging_Delta_1,
               Param.Hanging_Delta_2,
               Option => False, Accumulate => False);
         when Hanging_2 => -- wisi-hanging%
            return Indent_Hanging_1
              (Data, Tree, Tokens, Tree_Indenting, Indenting_Comment, Param.Hanging_Delta_1,
               Param.Hanging_Delta_2,
               Option => True, Accumulate => True);
         when Hanging_3 => -- wisi-hanging%-
            return Indent_Hanging_1
              (Data, Tree, Tokens, Tree_Indenting, Indenting_Comment, Param.Hanging_Delta_1,
               Param.Hanging_Delta_2,
               Option => True, Accumulate => False);
         end case;
      end case;
   end Indent_Compute_Delta;

   procedure Indent_Token_1
     (Data              : in out Parse_Data_Type;
      Indenting_Token   : in     Augmented_Token'Class;
      Delta_Indent      : in     Delta_Type;
      Indenting_Comment : in     Boolean)
   is
      --  Aplly Delta_Indent to Indenting_Token
      First_Line : constant Line_Number_Type := Indenting_Token.First_Line (Indenting_Comment);
      Last_Line  : constant Line_Number_Type := Indenting_Token.Last_Line (Indenting_Comment);
   begin
      if Trace_Action > Detail then
         Ada.Text_IO.Put_Line
           (";; indent_token_1: " & Indenting_Token.Image (Data.Descriptor.all) & " " & Image (Delta_Indent) &
              Line_Number_Type'Image (First_Line) & " .." & Line_Number_Type'Image (Last_Line) &
              (if Indenting_Comment then " comment" else ""));
      end if;

      for Line in First_Line .. Last_Line loop
         if Data.Indent_Comment_Col_0 then
            declare
               use all type Ada.Text_IO.Count;
               Indent : Boolean := True;
            begin
               if Data.Line_Begin_Token.all (Line - 1) /= Augmented_Token_Arrays.No_Index then
                  for Tok of Data.Terminals (Data.Line_Begin_Token.all (Line - 1)).Non_Grammar loop
                     if Tok.Line = Line and then
                       Tok.ID in Data.First_Comment_ID .. Data.Last_Comment_ID and then
                       Tok.Column = 0
                     then
                        Indent := False;
                        exit;
                     end if;
                  end loop;
               end if;

               if Indent then
                  Indent_Line (Data, Line, Delta_Indent);
               else
                  Indent_Line (Data, Line, (Simple, (Int, 0)));
               end if;
            end;
         else
            Indent_Line (Data, Line, Delta_Indent);
         end if;
      end loop;
   end Indent_Token_1;

   function Last_Line
     (Token             : in Augmented_Token;
      Indenting_Comment : in Boolean)
     return Line_Number_Type
   is begin
      return
        (if Indenting_Comment then
           (if Token.Last_Trailing_Comment_Line = Invalid_Line_Number
            then Token.Line
            else Token.Last_Trailing_Comment_Line)
         else
           (if Token.Last_Indent_Line = Invalid_Line_Number
            then Token.Line
            else Token.Last_Indent_Line));
   end Last_Line;

end Wisi;
