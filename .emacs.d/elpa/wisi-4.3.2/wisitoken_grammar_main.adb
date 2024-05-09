--  generated parser support file. -*- buffer-read-only:t  -*-
--  command line: wisitoken-bnf-generate.exe  --generate LALR Ada re2c wisitoken_grammar.wy
--

--  Copyright (C) 2017 - 2023 Free Software Foundation, Inc.
--
--  Author: Stephen Leake <stephe-leake@stephe-leake.org>
--
--  This file is part of GNU Emacs.
--
--  GNU Emacs is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  GNU Emacs is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

with SAL;
with WisiToken.Lexer.re2c;
with wisitoken_grammar_re2c_c;
with WisiToken.Parse.LR;
with Wisitoken_Grammar_Actions; use Wisitoken_Grammar_Actions;
package body Wisitoken_Grammar_Main is

   function Is_Block_Delimited (ID : in WisiToken.Token_ID) return Boolean
   is begin
      case To_Token_Enum (ID) is
      when
         COMMENT_ID |
         RAW_CODE_ID |
         REGEXP_ID |
         ACTION_ID |
         STRING_LITERAL_DOUBLE_ID |
         STRING_LITERAL_SINGLE_ID => return True;
      when others => return False;
      end case;
   end Is_Block_Delimited;

   function Same_Block_Delimiters (ID : in WisiToken.Token_ID) return Boolean
   is begin
      case To_Token_Enum (ID) is
      when COMMENT_ID => return False;
      when RAW_CODE_ID => return False;
      when REGEXP_ID => return False;
      when ACTION_ID => return False;
      when STRING_LITERAL_DOUBLE_ID => return True;
      when STRING_LITERAL_SINGLE_ID => return True;
      when others => return False;
      end case;
   end Same_Block_Delimiters;

   function Escape_Delimiter_Doubled (ID : in WisiToken.Token_ID) return Boolean
   is begin
      case To_Token_Enum (ID) is
      when others => return False;
      end case;
   end Escape_Delimiter_Doubled;

   function Start_Delimiter_Length (ID : in WisiToken.Token_ID) return Integer
   is begin
      case To_Token_Enum (ID) is
      when COMMENT_ID => return 2;
      when RAW_CODE_ID => return 2;
      when REGEXP_ID => return 2;
      when ACTION_ID => return 2;
      when STRING_LITERAL_DOUBLE_ID => return 1;
      when STRING_LITERAL_SINGLE_ID => return 1;
      when others => raise SAL.Programmer_Error; return 0;
      end case;
   end Start_Delimiter_Length;

   function End_Delimiter_Length (ID : in WisiToken.Token_ID) return Integer
   is begin
      case To_Token_Enum (ID) is
      when
         COMMENT_ID |
         STRING_LITERAL_DOUBLE_ID |
         STRING_LITERAL_SINGLE_ID => return 1;
      when RAW_CODE_ID => return 2;
      when REGEXP_ID => return 2;
      when ACTION_ID => return 2;
      when others => raise SAL.Programmer_Error; return 0;
      end case;
   end End_Delimiter_Length;

   function New_Line_Is_End_Delimiter (ID : in WisiToken.Token_ID) return Boolean
   is begin
      return
        (case To_Token_Enum (ID) is
         when COMMENT_ID => True,
         when RAW_CODE_ID => False,
         when REGEXP_ID => False,
         when ACTION_ID => False,
         when STRING_LITERAL_DOUBLE_ID => True,
         when STRING_LITERAL_SINGLE_ID => True,
         when others => raise SAL.Programmer_Error);
   end New_Line_Is_End_Delimiter;

   function Find_End_Delimiter
     (Source      : in WisiToken.Lexer.Source;
      ID          : in WisiToken.Token_ID;
      Token_Start : in WisiToken.Buffer_Pos)
     return WisiToken.Buffer_Pos
   is begin
      return
        (case To_Token_Enum (ID) is
         when COMMENT_ID => WisiToken.Lexer.Find_New_Line (Source, Token_Start),
         when RAW_CODE_ID => WisiToken.Lexer.Find_String (Source, Token_Start, "}%"),
         when REGEXP_ID => WisiToken.Lexer.Find_String (Source, Token_Start, "]%"),
         when ACTION_ID => WisiToken.Lexer.Find_String (Source, Token_Start, ")%"),
         when STRING_LITERAL_DOUBLE_ID => WisiToken.Lexer.Find_String_Or_New_Line (Source, Token_Start, """"),
         when STRING_LITERAL_SINGLE_ID => WisiToken.Lexer.Find_String_Or_New_Line (Source, Token_Start, """"),
         when others => raise SAL.Programmer_Error);
   end Find_End_Delimiter;

   function Find_Scan_End
     (Source   : in WisiToken.Lexer.Source;
      ID       : in WisiToken.Token_ID;
      Region   : in WisiToken.Buffer_Region;
      Inserted : in Boolean;
      Start    : in Boolean)
     return WisiToken.Buffer_Pos
   is
      use WisiToken;
   begin
      return
        (case To_Token_Enum (ID) is
         when COMMENT_ID =>
         (if Inserted then Region.Last
          elsif Start then Region.Last
          else Lexer.Find_New_Line (Source, Region.Last)),
         when RAW_CODE_ID =>
         (if Inserted then Region.Last
          elsif Start then Region.Last
          else Lexer.Find_String (Source, Region.First, "}%")),
         when REGEXP_ID =>
         (if Inserted then Region.Last
          elsif Start then Region.Last
          else Lexer.Find_String (Source, Region.First, "]%")),
         when ACTION_ID =>
         (if Inserted then Region.Last
          elsif Start then Region.Last
          else Lexer.Find_String (Source, Region.First, ")%")),
         when STRING_LITERAL_DOUBLE_ID => Lexer.Find_New_Line (Source, Region.Last),
         when STRING_LITERAL_SINGLE_ID => Lexer.Find_New_Line (Source, Region.Last),
         when others => raise SAL.Programmer_Error);
   end Find_Scan_End;

   function Contains_End_Delimiter
     (Source : in WisiToken.Lexer.Source;
      ID     : in WisiToken.Token_ID;
      Region : in WisiToken.Buffer_Region)
     return WisiToken.Base_Buffer_Pos
   is
      use WisiToken;
   begin
      return
        (case To_Token_Enum (ID) is
         when COMMENT_ID => Lexer.Find_New_Line (Source, Region),
         when RAW_CODE_ID => Lexer.Find_String_Or_New_Line (Source, Region, "}%"),
         when REGEXP_ID => Lexer.Find_String_Or_New_Line (Source, Region, "]%"),
         when ACTION_ID => Lexer.Find_String_Or_New_Line (Source, Region, ")%"),
         when STRING_LITERAL_DOUBLE_ID => Lexer.Find_String_Or_New_Line (Source, Region, """"),
         when STRING_LITERAL_SINGLE_ID => Lexer.Find_String_Or_New_Line (Source, Region, "'"),
         when others => raise SAL.Programmer_Error);
   end Contains_End_Delimiter;

   function Line_Begin_Char_Pos
    (Source : in WisiToken.Lexer.Source;
     Token  : in WisiToken.Lexer.Token;
     Line   : in WisiToken.Line_Number_Type)
   return WisiToken.Buffer_Pos
   is
      use all type WisiToken.Base_Buffer_Pos;
   begin
      case To_Token_Enum (Token.ID) is
      when NEW_LINE_ID => return Token.Char_Region.Last + 1;
      when COMMENT_ID => return Token.Char_Region.Last + 1;
      when RAW_CODE_ID => return WisiToken.Lexer.Line_Begin_Char_Pos (Source, Token, Line);
      when REGEXP_ID => return WisiToken.Lexer.Line_Begin_Char_Pos (Source, Token, Line);
      when ACTION_ID => return WisiToken.Lexer.Line_Begin_Char_Pos (Source, Token, Line);
      when others => raise SAL.Programmer_Error;
      end case;
   end Line_Begin_Char_Pos;

   function Can_Contain_New_Line (ID : in WisiToken.Token_ID) return Boolean
   is begin
      case To_Token_Enum (ID) is
      when NEW_LINE_ID => return True;
      when COMMENT_ID => return True;
      when RAW_CODE_ID => return True;
      when REGEXP_ID => return True;
      when ACTION_ID => return True;
      when others => return False;
      end case;
   end Can_Contain_New_Line;

   function Terminated_By_New_Line (ID : in WisiToken.Token_ID) return Boolean
   is begin
      case To_Token_Enum (ID) is
      when NEW_LINE_ID => return True;
      when COMMENT_ID => return True;
      when STRING_LITERAL_DOUBLE_ID => return True;
      when STRING_LITERAL_SINGLE_ID => return True;
      when others => return False;
      end case;
   end Terminated_By_New_Line;

   package Lexer is new WisiToken.Lexer.re2c
     (wisitoken_grammar_re2c_c.New_Lexer,
      wisitoken_grammar_re2c_c.Free_Lexer,
      wisitoken_grammar_re2c_c.Reset_Lexer,
      wisitoken_grammar_re2c_c.Set_Verbosity,
      wisitoken_grammar_re2c_c.Set_Position,
      wisitoken_grammar_re2c_c.Next_Token,
      Is_Block_Delimited,
      Same_Block_Delimiters,
      Escape_Delimiter_Doubled,
      Start_Delimiter_Length,
      End_Delimiter_Length,
      New_Line_Is_End_Delimiter,
      Find_End_Delimiter,
      Contains_End_Delimiter,
      Find_Scan_End,
      Line_Begin_Char_Pos,
      Can_Contain_New_Line,
      Terminated_By_New_Line);

   function Create_Parse_Table
     return WisiToken.Parse.LR.Parse_Table_Ptr
   is
      use WisiToken.Parse.LR;
      Table : constant Parse_Table_Ptr := new Parse_Table
        (State_First       => 0,
         State_Last        => 162,
         First_Terminal    => 3,
         Last_Terminal     => 42,
         First_Nonterminal => 43,
         Last_Nonterminal  => 68);
   begin
      declare
         procedure Subr_1
         is begin
            Table.States (0).Action_List.Set_Capacity (2);
            Add_Action (Table.States (0), 30, (48, 0), 1);
            Add_Action (Table.States (0), 39, (53, 0), 2);
            Table.States (0).Goto_List.Set_Capacity (4);
            Add_Goto (Table.States (0), 48, 3);
            Add_Goto (Table.States (0), 53, 4);
            Add_Goto (Table.States (0), 67, 5);
            Add_Goto (Table.States (0), 68, 6);
            Table.States (1).Action_List.Set_Capacity (10);
            Add_Action (Table.States (1), 4, (48, 6), 7);
            Add_Action (Table.States (1), 5, (48, 7), 8);
            Add_Action (Table.States (1), 6, (48, 9), 9);
            Add_Action (Table.States (1), 7, (48, 16), 10);
            Add_Action (Table.States (1), 8, (48, 14), 11);
            Add_Action (Table.States (1), 9, (48, 12), 12);
            Add_Action (Table.States (1), 11, (48, 5), 13);
            Add_Action (Table.States (1), 12, (48, 2), 14);
            Add_Action (Table.States (1), 16, (48, 0), 15);
            Add_Action (Table.States (1), 39, (48, 10), 16);
            Table.States (2).Action_List.Set_Capacity (3);
            Add_Action (Table.States (2), 21, (53, 0), 17);
            Add_Action (Table.States (2), 22, (53, 3), 18);
            Add_Action (Table.States (2), 28, (57, 0), 19);
            Table.States (2).Goto_List.Set_Capacity (2);
            Add_Goto (Table.States (2), 57, 20);
            Add_Goto (Table.States (2), 58, 21);
            Table.States (3).Action_List.Set_Capacity (3);
            Add_Action (Table.States (3), (30, 39, 42), (67, 0),  1);
            Table.States (4).Action_List.Set_Capacity (3);
            Add_Action (Table.States (4), (30, 39, 42), (67, 1),  1);
            Table.States (5).Action_List.Set_Capacity (3);
            Add_Action (Table.States (5), (30, 39, 42), (68, 1),  1);
            Table.States (6).Action_List.Set_Capacity (3);
            Add_Action (Table.States (6), 30, (48, 0), 1);
            Add_Action (Table.States (6), 39, (53, 0), 2);
            Add_Action (Table.States (6), 42, Accept_It, (43, 0),  1);
            Table.States (6).Goto_List.Set_Capacity (3);
            Add_Goto (Table.States (6), 48, 3);
            Add_Goto (Table.States (6), 53, 4);
            Add_Goto (Table.States (6), 67, 22);
            Table.States (7).Action_List.Set_Capacity (1);
            Add_Action (Table.States (7), 39, (49, 0), 23);
            Table.States (7).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (7), 49, 24);
            Table.States (8).Action_List.Set_Capacity (4);
            Add_Action (Table.States (8), 3, (45, 2), 25);
            Add_Action (Table.States (8), 14, (45, 1), 26);
            Add_Action (Table.States (8), 15, (45, 0), 27);
            Add_Action (Table.States (8), 39, (45, 3), 28);
            Table.States (8).Goto_List.Set_Capacity (3);
            Add_Goto (Table.States (8), 45, 29);
            Add_Goto (Table.States (8), 46, 30);
            Add_Goto (Table.States (8), 49, 31);
            Table.States (9).Action_List.Set_Capacity (4);
            Add_Action (Table.States (9), 3, (45, 2), 25);
            Add_Action (Table.States (9), 14, (45, 1), 26);
            Add_Action (Table.States (9), 15, (45, 0), 27);
            Add_Action (Table.States (9), 39, (45, 3), 32);
            Table.States (9).Goto_List.Set_Capacity (2);
            Add_Goto (Table.States (9), 45, 29);
            Add_Goto (Table.States (9), 46, 33);
            Table.States (10).Action_List.Set_Capacity (1);
            Add_Action (Table.States (10), 9, (48, 16), 34);
            Table.States (11).Action_List.Set_Capacity (1);
            Add_Action (Table.States (11), 39, (48, 14), 35);
            Table.States (12).Action_List.Set_Capacity (1);
            Add_Action (Table.States (12), 39, (48, 12), 36);
            Table.States (13).Action_List.Set_Capacity (1);
            Add_Action (Table.States (13), 39, (48, 5), 37);
            Table.States (14).Action_List.Set_Capacity (1);
            Add_Action (Table.States (14), 28, (48, 2), 38);
            Table.States (15).Action_List.Set_Capacity (1);
            Add_Action (Table.States (15), 28, (48, 0), 39);
            Table.States (16).Action_List.Set_Capacity (7);
            Add_Action (Table.States (16), 18, (44, 0), 40);
            Add_Action (Table.States (16), 30, Reduce, (48, 11),  2);
            Add_Action (Table.States (16), 38, (51, 1), 41);
            Add_Action (Table.States (16), 39, (51, 0), 42);
            Add_Conflict (Table.States (16), 39, (48, 11),  2);
            Add_Action (Table.States (16), 40, (44, 1), 43);
            Add_Action (Table.States (16), 41, (44, 2), 44);
            Add_Action (Table.States (16), 42, Reduce, (48, 11),  2);
            Table.States (16).Goto_List.Set_Capacity (3);
            Add_Goto (Table.States (16), 44, 45);
            Add_Goto (Table.States (16), 51, 46);
            Add_Goto (Table.States (16), 52, 47);
            Table.States (17).Action_List.Set_Capacity (10);
            Add_Action (Table.States (17), 20, Reduce, (56, 0),  0);
            Add_Action (Table.States (17), 25, (64, 0), 48);
            Add_Action (Table.States (17), 26, (63, 0), 49);
            Add_Action (Table.States (17), 27, (62, 0), 50);
            Add_Action (Table.States (17), 28, (57, 0), 19);
            Add_Action (Table.States (17), 30, Reduce, (56, 0),  0);
            Add_Action (Table.States (17), 36, Reduce, (56, 0),  0);
            Add_Action (Table.States (17), 39, (59, 1), 51);
            Add_Conflict (Table.States (17), 39, (56, 0),  0);
            Add_Action (Table.States (17), 41, (61, 1), 52);
            Add_Action (Table.States (17), 42, Reduce, (56, 0),  0);
            Table.States (17).Goto_List.Set_Capacity (10);
            Add_Goto (Table.States (17), 55, 53);
            Add_Goto (Table.States (17), 56, 54);
            Add_Goto (Table.States (17), 57, 20);
            Add_Goto (Table.States (17), 58, 55);
            Add_Goto (Table.States (17), 59, 56);
            Add_Goto (Table.States (17), 60, 57);
            Add_Goto (Table.States (17), 61, 58);
            Add_Goto (Table.States (17), 62, 59);
            Add_Goto (Table.States (17), 63, 60);
            Add_Goto (Table.States (17), 64, 61);
            Table.States (18).Action_List.Set_Capacity (10);
            Add_Action (Table.States (18), 20, Reduce, (56, 0),  0);
            Add_Action (Table.States (18), 25, (64, 0), 48);
            Add_Action (Table.States (18), 26, (63, 0), 49);
            Add_Action (Table.States (18), 27, (62, 0), 50);
            Add_Action (Table.States (18), 28, (57, 0), 19);
            Add_Action (Table.States (18), 30, Reduce, (56, 0),  0);
            Add_Action (Table.States (18), 36, Reduce, (56, 0),  0);
            Add_Action (Table.States (18), 39, (59, 1), 51);
            Add_Conflict (Table.States (18), 39, (56, 0),  0);
            Add_Action (Table.States (18), 41, (61, 1), 52);
            Add_Action (Table.States (18), 42, Reduce, (56, 0),  0);
            Table.States (18).Goto_List.Set_Capacity (10);
            Add_Goto (Table.States (18), 55, 62);
            Add_Goto (Table.States (18), 56, 54);
            Add_Goto (Table.States (18), 57, 20);
            Add_Goto (Table.States (18), 58, 55);
            Add_Goto (Table.States (18), 59, 56);
            Add_Goto (Table.States (18), 60, 57);
            Add_Goto (Table.States (18), 61, 58);
            Add_Goto (Table.States (18), 62, 59);
            Add_Goto (Table.States (18), 63, 60);
            Add_Goto (Table.States (18), 64, 61);
            Table.States (19).Action_List.Set_Capacity (1);
            Add_Action (Table.States (19), 39, (57, 0), 63);
            Table.States (20).Action_List.Set_Capacity (8);
            Add_Action (Table.States (20), (21, 22, 25, 26, 27, 28, 39, 41), (58, 1),  1);
            Table.States (21).Action_List.Set_Capacity (3);
            Add_Action (Table.States (21), 21, (53, 1), 64);
            Add_Action (Table.States (21), 22, (53, 2), 65);
            Add_Action (Table.States (21), 28, (57, 0), 19);
            Table.States (21).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (21), 57, 66);
            Table.States (22).Action_List.Set_Capacity (3);
            Add_Action (Table.States (22), (30, 39, 42), (68, 0),  2);
            Table.States (23).Action_List.Set_Capacity (2);
            Add_Action (Table.States (23), (17, 39), (49, 0),  1);
            Table.States (24).Action_List.Set_Capacity (2);
            Add_Action (Table.States (24), 17, (48, 6), 67);
            Add_Action (Table.States (24), 39, (49, 1), 68);
            Table.States (25).Action_List.Set_Capacity (1);
            Add_Action (Table.States (25), 39, (45, 2), 69);
            Table.States (26).Action_List.Set_Capacity (1);
            Add_Action (Table.States (26), 39, (45, 1), 70);
            Table.States (27).Action_List.Set_Capacity (1);
            Add_Action (Table.States (27), 39, (45, 0), 71);
            Table.States (28).Action_List.Set_Capacity (5);
            Add_Action (Table.States (28), 13, Reduce, (45, 3),  1);
            Add_Action (Table.States (28), 20, Reduce, (45, 3),  1);
            Add_Action (Table.States (28), 30, Reduce, (49, 0),  1);
            Add_Action (Table.States (28), 39, Reduce, (49, 0),  1);
            Add_Action (Table.States (28), 42, Reduce, (49, 0),  1);
            Table.States (29).Action_List.Set_Capacity (2);
            Add_Action (Table.States (29), (13, 20), (46, 0),  1);
            Table.States (30).Action_List.Set_Capacity (2);
            Add_Action (Table.States (30), 13, (48, 8), 72);
            Add_Action (Table.States (30), 20, (46, 1), 73);
            Table.States (31).Action_List.Set_Capacity (3);
            Add_Action (Table.States (31), 30, Reduce, (48, 7),  3);
            Add_Action (Table.States (31), 39, (49, 1), 68);
            Add_Conflict (Table.States (31), 39, (48, 7),  3);
            Add_Action (Table.States (31), 42, Reduce, (48, 7),  3);
            Table.States (32).Action_List.Set_Capacity (2);
            Add_Action (Table.States (32), (13, 20), (45, 3),  1);
            Table.States (33).Action_List.Set_Capacity (2);
            Add_Action (Table.States (33), 13, (48, 9), 74);
            Add_Action (Table.States (33), 20, (46, 1), 73);
            Table.States (34).Action_List.Set_Capacity (3);
            Add_Action (Table.States (34), (30, 39, 42), (48, 16),  3);
            Table.States (35).Action_List.Set_Capacity (2);
            Add_Action (Table.States (35), 10, (48, 15), 75);
            Add_Action (Table.States (35), 23, (48, 14), 76);
            Table.States (36).Action_List.Set_Capacity (2);
            Add_Action (Table.States (36), 10, (48, 13), 77);
            Add_Action (Table.States (36), 23, (48, 12), 78);
            Table.States (37).Action_List.Set_Capacity (3);
            Add_Action (Table.States (37), 18, (44, 0), 40);
            Add_Action (Table.States (37), 40, (44, 1), 43);
            Add_Action (Table.States (37), 41, (44, 2), 44);
            Table.States (37).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (37), 44, 79);
            Table.States (38).Action_List.Set_Capacity (1);
            Add_Action (Table.States (38), 39, (48, 2), 80);
            Table.States (39).Action_List.Set_Capacity (1);
            Add_Action (Table.States (39), 39, (48, 0), 81);
            Table.States (40).Action_List.Set_Capacity (7);
            Add_Action (Table.States (40), (18, 30, 38, 39, 40, 41, 42), (44, 0),  1);
            Table.States (41).Action_List.Set_Capacity (7);
            Add_Action (Table.States (41), (18, 30, 38, 39, 40, 41, 42), (51, 1),  1);
            Table.States (42).Action_List.Set_Capacity (7);
            Add_Action (Table.States (42), (18, 30, 38, 39, 40, 41, 42), (51, 0),  1);
            Table.States (43).Action_List.Set_Capacity (7);
            Add_Action (Table.States (43), (18, 30, 38, 39, 40, 41, 42), (44, 1),  1);
            Table.States (44).Action_List.Set_Capacity (7);
            Add_Action (Table.States (44), (18, 30, 38, 39, 40, 41, 42), (44, 2),  1);
            Table.States (45).Action_List.Set_Capacity (7);
            Add_Action (Table.States (45), (18, 30, 38, 39, 40, 41, 42), (51, 2),  1);
            Table.States (46).Action_List.Set_Capacity (7);
            Add_Action (Table.States (46), (18, 30, 38, 39, 40, 41, 42), (52, 0),  1);
            Table.States (47).Action_List.Set_Capacity (7);
            Add_Action (Table.States (47), 18, (44, 0), 40);
            Add_Action (Table.States (47), 30, Reduce, (48, 10),  3);
            Add_Action (Table.States (47), 38, (51, 1), 41);
            Add_Action (Table.States (47), 39, (51, 0), 42);
            Add_Conflict (Table.States (47), 39, (48, 10),  3);
            Add_Action (Table.States (47), 40, (44, 1), 43);
            Add_Action (Table.States (47), 41, (44, 2), 44);
            Add_Action (Table.States (47), 42, Reduce, (48, 10),  3);
            Table.States (47).Goto_List.Set_Capacity (2);
            Add_Goto (Table.States (47), 44, 45);
            Add_Goto (Table.States (47), 51, 82);
            Table.States (48).Action_List.Set_Capacity (6);
            Add_Action (Table.States (48), 25, (64, 0), 48);
            Add_Action (Table.States (48), 26, (63, 0), 49);
            Add_Action (Table.States (48), 27, (62, 0), 50);
            Add_Action (Table.States (48), 28, (57, 0), 19);
            Add_Action (Table.States (48), 39, (59, 1), 51);
            Add_Action (Table.States (48), 41, (61, 1), 52);
            Table.States (48).Goto_List.Set_Capacity (10);
            Add_Goto (Table.States (48), 57, 20);
            Add_Goto (Table.States (48), 58, 83);
            Add_Goto (Table.States (48), 59, 56);
            Add_Goto (Table.States (48), 60, 84);
            Add_Goto (Table.States (48), 61, 58);
            Add_Goto (Table.States (48), 62, 59);
            Add_Goto (Table.States (48), 63, 60);
            Add_Goto (Table.States (48), 64, 61);
            Add_Goto (Table.States (48), 65, 85);
            Add_Goto (Table.States (48), 66, 86);
            Table.States (49).Action_List.Set_Capacity (6);
            Add_Action (Table.States (49), 25, (64, 0), 48);
            Add_Action (Table.States (49), 26, (63, 0), 49);
            Add_Action (Table.States (49), 27, (62, 0), 50);
            Add_Action (Table.States (49), 28, (57, 0), 19);
            Add_Action (Table.States (49), 39, (59, 1), 51);
            Add_Action (Table.States (49), 41, (61, 1), 52);
            Table.States (49).Goto_List.Set_Capacity (10);
            Add_Goto (Table.States (49), 57, 20);
            Add_Goto (Table.States (49), 58, 83);
            Add_Goto (Table.States (49), 59, 56);
            Add_Goto (Table.States (49), 60, 84);
            Add_Goto (Table.States (49), 61, 58);
            Add_Goto (Table.States (49), 62, 59);
            Add_Goto (Table.States (49), 63, 60);
            Add_Goto (Table.States (49), 64, 61);
            Add_Goto (Table.States (49), 65, 87);
            Add_Goto (Table.States (49), 66, 86);
            Table.States (50).Action_List.Set_Capacity (6);
            Add_Action (Table.States (50), 25, (64, 0), 48);
            Add_Action (Table.States (50), 26, (63, 0), 49);
            Add_Action (Table.States (50), 27, (62, 0), 50);
            Add_Action (Table.States (50), 28, (57, 0), 19);
            Add_Action (Table.States (50), 39, (59, 1), 51);
            Add_Action (Table.States (50), 41, (61, 1), 52);
            Table.States (50).Goto_List.Set_Capacity (10);
            Add_Goto (Table.States (50), 57, 20);
            Add_Goto (Table.States (50), 58, 83);
            Add_Goto (Table.States (50), 59, 56);
            Add_Goto (Table.States (50), 60, 84);
            Add_Goto (Table.States (50), 61, 58);
            Add_Goto (Table.States (50), 62, 59);
            Add_Goto (Table.States (50), 63, 60);
            Add_Goto (Table.States (50), 64, 61);
            Add_Goto (Table.States (50), 65, 88);
            Add_Goto (Table.States (50), 66, 86);
            Table.States (51).Action_List.Set_Capacity (17);
            Add_Action (Table.States (51), 19, Reduce, (61, 0),  1);
            Add_Action (Table.States (51), 20, Reduce, (61, 0),  1);
            Add_Action (Table.States (51), 23, (59, 1), 89);
            Add_Action (Table.States (51), 25, Reduce, (61, 0),  1);
            Add_Action (Table.States (51), 26, Reduce, (61, 0),  1);
            Add_Action (Table.States (51), 27, Reduce, (61, 0),  1);
            Add_Action (Table.States (51), 30, Reduce, (61, 0),  1);
            Add_Action (Table.States (51), 31, (64, 4), 90);
            Add_Action (Table.States (51), 32, (63, 2), 91);
            Add_Action (Table.States (51), 33, Reduce, (61, 0),  1);
            Add_Action (Table.States (51), 34, Reduce, (61, 0),  1);
            Add_Action (Table.States (51), 35, Reduce, (61, 0),  1);
            Add_Action (Table.States (51), 36, Reduce, (61, 0),  1);
            Add_Action (Table.States (51), 37, (64, 5), 92);
            Add_Action (Table.States (51), 39, Reduce, (61, 0),  1);
            Add_Action (Table.States (51), 41, Reduce, (61, 0),  1);
            Add_Action (Table.States (51), 42, Reduce, (61, 0),  1);
            Table.States (52).Action_List.Set_Capacity (14);
            Add_Action (Table.States (52), 19, Reduce, (61, 1),  1);
            Add_Action (Table.States (52), 20, Reduce, (61, 1),  1);
            Add_Action (Table.States (52), 25, Reduce, (61, 1),  1);
            Add_Action (Table.States (52), 26, Reduce, (61, 1),  1);
            Add_Action (Table.States (52), 27, Reduce, (61, 1),  1);
            Add_Action (Table.States (52), 30, Reduce, (61, 1),  1);
            Add_Action (Table.States (52), 32, (63, 3), 93);
            Add_Action (Table.States (52), 33, Reduce, (61, 1),  1);
            Add_Action (Table.States (52), 34, Reduce, (61, 1),  1);
            Add_Action (Table.States (52), 35, Reduce, (61, 1),  1);
            Add_Action (Table.States (52), 36, Reduce, (61, 1),  1);
            Add_Action (Table.States (52), 39, Reduce, (61, 1),  1);
            Add_Action (Table.States (52), 41, Reduce, (61, 1),  1);
            Add_Action (Table.States (52), 42, Reduce, (61, 1),  1);
            Table.States (53).Action_List.Set_Capacity (5);
            Add_Action (Table.States (53), 20, (55, 1), 94);
            Add_Action (Table.States (53), 30, (55, 2), 95);
            Add_Conflict (Table.States (53), 30, (54, 1),  0);
            Add_Action (Table.States (53), 36, (54, 0), 96);
            Add_Action (Table.States (53), 39, Reduce, (54, 1),  0);
            Add_Action (Table.States (53), 42, Reduce, (54, 1),  0);
            Table.States (53).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (53), 54, 97);
            Table.States (54).Action_List.Set_Capacity (5);
            Add_Action (Table.States (54), (20, 30, 36, 39, 42), (55, 0),  1);
            Table.States (55).Action_List.Set_Capacity (6);
            Add_Action (Table.States (55), 25, (64, 0), 48);
            Add_Action (Table.States (55), 26, (63, 0), 49);
            Add_Action (Table.States (55), 27, (62, 0), 50);
            Add_Action (Table.States (55), 28, (57, 0), 19);
            Add_Action (Table.States (55), 39, (59, 1), 51);
            Add_Action (Table.States (55), 41, (61, 1), 52);
            Table.States (55).Goto_List.Set_Capacity (7);
            Add_Goto (Table.States (55), 57, 66);
            Add_Goto (Table.States (55), 59, 56);
            Add_Goto (Table.States (55), 60, 98);
            Add_Goto (Table.States (55), 61, 58);
            Add_Goto (Table.States (55), 62, 59);
            Add_Goto (Table.States (55), 63, 60);
            Add_Goto (Table.States (55), 64, 61);
         end Subr_1;
         procedure Subr_2
         is begin
            Table.States (56).Action_List.Set_Capacity (13);
            Add_Action (Table.States (56), (19, 20, 25, 26, 27, 30, 33, 34, 35, 36, 39, 41, 42), (60, 1),  1);
            Table.States (57).Action_List.Set_Capacity (10);
            Add_Action (Table.States (57), 19, (56, 3), 99);
            Add_Action (Table.States (57), 20, Reduce, (56, 1),  1);
            Add_Action (Table.States (57), 25, (64, 0), 48);
            Add_Action (Table.States (57), 26, (63, 0), 49);
            Add_Action (Table.States (57), 27, (62, 0), 50);
            Add_Action (Table.States (57), 30, Reduce, (56, 1),  1);
            Add_Action (Table.States (57), 36, Reduce, (56, 1),  1);
            Add_Action (Table.States (57), 39, (59, 1), 51);
            Add_Conflict (Table.States (57), 39, (56, 1),  1);
            Add_Action (Table.States (57), 41, (61, 1), 52);
            Add_Action (Table.States (57), 42, Reduce, (56, 1),  1);
            Table.States (57).Goto_List.Set_Capacity (5);
            Add_Goto (Table.States (57), 59, 100);
            Add_Goto (Table.States (57), 61, 58);
            Add_Goto (Table.States (57), 62, 59);
            Add_Goto (Table.States (57), 63, 60);
            Add_Goto (Table.States (57), 64, 61);
            Table.States (58).Action_List.Set_Capacity (13);
            Add_Action (Table.States (58), (19, 20, 25, 26, 27, 30, 33, 34, 35, 36, 39, 41, 42), (59, 0),  1);
            Table.States (59).Action_List.Set_Capacity (13);
            Add_Action (Table.States (59), (19, 20, 25, 26, 27, 30, 33, 34, 35, 36, 39, 41, 42), (61, 4),  1);
            Table.States (60).Action_List.Set_Capacity (13);
            Add_Action (Table.States (60), (19, 20, 25, 26, 27, 30, 33, 34, 35, 36, 39, 41, 42), (61, 2),  1);
            Table.States (61).Action_List.Set_Capacity (13);
            Add_Action (Table.States (61), (19, 20, 25, 26, 27, 30, 33, 34, 35, 36, 39, 41, 42), (61, 3),  1);
            Table.States (62).Action_List.Set_Capacity (5);
            Add_Action (Table.States (62), 20, (55, 1), 94);
            Add_Action (Table.States (62), 30, (55, 2), 95);
            Add_Conflict (Table.States (62), 30, (54, 1),  0);
            Add_Action (Table.States (62), 36, (54, 0), 96);
            Add_Action (Table.States (62), 39, Reduce, (54, 1),  0);
            Add_Action (Table.States (62), 42, Reduce, (54, 1),  0);
            Table.States (62).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (62), 54, 101);
            Table.States (63).Action_List.Set_Capacity (1);
            Add_Action (Table.States (63), 23, (57, 0), 102);
            Table.States (64).Action_List.Set_Capacity (10);
            Add_Action (Table.States (64), 20, Reduce, (56, 0),  0);
            Add_Action (Table.States (64), 25, (64, 0), 48);
            Add_Action (Table.States (64), 26, (63, 0), 49);
            Add_Action (Table.States (64), 27, (62, 0), 50);
            Add_Action (Table.States (64), 28, (57, 0), 19);
            Add_Action (Table.States (64), 30, Reduce, (56, 0),  0);
            Add_Action (Table.States (64), 36, Reduce, (56, 0),  0);
            Add_Action (Table.States (64), 39, (59, 1), 51);
            Add_Conflict (Table.States (64), 39, (56, 0),  0);
            Add_Action (Table.States (64), 41, (61, 1), 52);
            Add_Action (Table.States (64), 42, Reduce, (56, 0),  0);
            Table.States (64).Goto_List.Set_Capacity (10);
            Add_Goto (Table.States (64), 55, 103);
            Add_Goto (Table.States (64), 56, 54);
            Add_Goto (Table.States (64), 57, 20);
            Add_Goto (Table.States (64), 58, 55);
            Add_Goto (Table.States (64), 59, 56);
            Add_Goto (Table.States (64), 60, 57);
            Add_Goto (Table.States (64), 61, 58);
            Add_Goto (Table.States (64), 62, 59);
            Add_Goto (Table.States (64), 63, 60);
            Add_Goto (Table.States (64), 64, 61);
            Table.States (65).Action_List.Set_Capacity (10);
            Add_Action (Table.States (65), 20, Reduce, (56, 0),  0);
            Add_Action (Table.States (65), 25, (64, 0), 48);
            Add_Action (Table.States (65), 26, (63, 0), 49);
            Add_Action (Table.States (65), 27, (62, 0), 50);
            Add_Action (Table.States (65), 28, (57, 0), 19);
            Add_Action (Table.States (65), 30, Reduce, (56, 0),  0);
            Add_Action (Table.States (65), 36, Reduce, (56, 0),  0);
            Add_Action (Table.States (65), 39, (59, 1), 51);
            Add_Conflict (Table.States (65), 39, (56, 0),  0);
            Add_Action (Table.States (65), 41, (61, 1), 52);
            Add_Action (Table.States (65), 42, Reduce, (56, 0),  0);
            Table.States (65).Goto_List.Set_Capacity (10);
            Add_Goto (Table.States (65), 55, 104);
            Add_Goto (Table.States (65), 56, 54);
            Add_Goto (Table.States (65), 57, 20);
            Add_Goto (Table.States (65), 58, 55);
            Add_Goto (Table.States (65), 59, 56);
            Add_Goto (Table.States (65), 60, 57);
            Add_Goto (Table.States (65), 61, 58);
            Add_Goto (Table.States (65), 62, 59);
            Add_Goto (Table.States (65), 63, 60);
            Add_Goto (Table.States (65), 64, 61);
            Table.States (66).Action_List.Set_Capacity (8);
            Add_Action (Table.States (66), (21, 22, 25, 26, 27, 28, 39, 41), (58, 0),  2);
            Table.States (67).Action_List.Set_Capacity (3);
            Add_Action (Table.States (67), (30, 39, 42), (48, 6),  4);
            Table.States (68).Action_List.Set_Capacity (4);
            Add_Action (Table.States (68), (17, 30, 39, 42), (49, 1),  2);
            Table.States (69).Action_List.Set_Capacity (2);
            Add_Action (Table.States (69), (13, 20), (45, 2),  2);
            Table.States (70).Action_List.Set_Capacity (2);
            Add_Action (Table.States (70), (13, 20), (45, 1),  2);
            Table.States (71).Action_List.Set_Capacity (2);
            Add_Action (Table.States (71), (13, 20), (45, 0),  2);
            Table.States (72).Action_List.Set_Capacity (1);
            Add_Action (Table.States (72), 16, (48, 8), 105);
            Table.States (73).Action_List.Set_Capacity (4);
            Add_Action (Table.States (73), 3, (45, 2), 25);
            Add_Action (Table.States (73), 14, (45, 1), 26);
            Add_Action (Table.States (73), 15, (45, 0), 27);
            Add_Action (Table.States (73), 39, (45, 3), 32);
            Table.States (73).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (73), 45, 106);
            Table.States (74).Action_List.Set_Capacity (1);
            Add_Action (Table.States (74), 16, (48, 9), 107);
            Table.States (75).Action_List.Set_Capacity (1);
            Add_Action (Table.States (75), 39, (50, 0), 108);
            Table.States (75).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (75), 50, 109);
            Table.States (76).Action_List.Set_Capacity (1);
            Add_Action (Table.States (76), 39, (48, 14), 110);
            Table.States (77).Action_List.Set_Capacity (1);
            Add_Action (Table.States (77), 39, (50, 0), 108);
            Table.States (77).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (77), 50, 111);
            Table.States (78).Action_List.Set_Capacity (1);
            Add_Action (Table.States (78), 39, (48, 12), 112);
            Table.States (79).Action_List.Set_Capacity (3);
            Add_Action (Table.States (79), (30, 39, 42), (48, 5),  4);
            Table.States (80).Action_List.Set_Capacity (1);
            Add_Action (Table.States (80), 24, (48, 2), 113);
            Table.States (81).Action_List.Set_Capacity (1);
            Add_Action (Table.States (81), 24, (48, 0), 114);
            Table.States (82).Action_List.Set_Capacity (7);
            Add_Action (Table.States (82), (18, 30, 38, 39, 40, 41, 42), (52, 1),  2);
            Table.States (83).Action_List.Set_Capacity (6);
            Add_Action (Table.States (83), 25, (64, 0), 48);
            Add_Action (Table.States (83), 26, (63, 0), 49);
            Add_Action (Table.States (83), 27, (62, 0), 50);
            Add_Action (Table.States (83), 28, (57, 0), 19);
            Add_Action (Table.States (83), 39, (59, 1), 51);
            Add_Action (Table.States (83), 41, (61, 1), 52);
            Table.States (83).Goto_List.Set_Capacity (8);
            Add_Goto (Table.States (83), 57, 66);
            Add_Goto (Table.States (83), 59, 56);
            Add_Goto (Table.States (83), 60, 84);
            Add_Goto (Table.States (83), 61, 58);
            Add_Goto (Table.States (83), 62, 59);
            Add_Goto (Table.States (83), 63, 60);
            Add_Goto (Table.States (83), 64, 61);
            Add_Goto (Table.States (83), 66, 115);
            Table.States (84).Action_List.Set_Capacity (9);
            Add_Action (Table.States (84), 20, Reduce, (66, 1),  1);
            Add_Action (Table.States (84), 25, (64, 0), 48);
            Add_Action (Table.States (84), 26, (63, 0), 49);
            Add_Action (Table.States (84), 27, (62, 0), 50);
            Add_Action (Table.States (84), 33, Reduce, (66, 1),  1);
            Add_Action (Table.States (84), 34, Reduce, (66, 1),  1);
            Add_Action (Table.States (84), 35, Reduce, (66, 1),  1);
            Add_Action (Table.States (84), 39, (59, 1), 51);
            Add_Action (Table.States (84), 41, (61, 1), 52);
            Table.States (84).Goto_List.Set_Capacity (5);
            Add_Goto (Table.States (84), 59, 100);
            Add_Goto (Table.States (84), 61, 58);
            Add_Goto (Table.States (84), 62, 59);
            Add_Goto (Table.States (84), 63, 60);
            Add_Goto (Table.States (84), 64, 61);
            Table.States (85).Action_List.Set_Capacity (1);
            Add_Action (Table.States (85), 33, (64, 0), 116);
            Table.States (86).Action_List.Set_Capacity (4);
            Add_Action (Table.States (86), 20, (66, 0), 117);
            Add_Action (Table.States (86), 33, Reduce, (65, 1),  1);
            Add_Action (Table.States (86), 34, Reduce, (65, 1),  1);
            Add_Action (Table.States (86), 35, Reduce, (65, 1),  1);
            Table.States (87).Action_List.Set_Capacity (1);
            Add_Action (Table.States (87), 34, (63, 0), 118);
            Table.States (88).Action_List.Set_Capacity (1);
            Add_Action (Table.States (88), 35, (62, 0), 119);
            Table.States (89).Action_List.Set_Capacity (5);
            Add_Action (Table.States (89), 25, (64, 0), 48);
            Add_Action (Table.States (89), 26, (63, 0), 49);
            Add_Action (Table.States (89), 27, (62, 0), 50);
            Add_Action (Table.States (89), 39, (61, 0), 120);
            Add_Action (Table.States (89), 41, (61, 1), 52);
            Table.States (89).Goto_List.Set_Capacity (4);
            Add_Goto (Table.States (89), 61, 121);
            Add_Goto (Table.States (89), 62, 59);
            Add_Goto (Table.States (89), 63, 60);
            Add_Goto (Table.States (89), 64, 61);
            Table.States (90).Action_List.Set_Capacity (13);
            Add_Action (Table.States (90), (19, 20, 25, 26, 27, 30, 33, 34, 35, 36, 39, 41, 42), (64, 4),  2);
            Table.States (91).Action_List.Set_Capacity (13);
            Add_Action (Table.States (91), (19, 20, 25, 26, 27, 30, 33, 34, 35, 36, 39, 41, 42), (63, 2),  2);
            Table.States (92).Action_List.Set_Capacity (13);
            Add_Action (Table.States (92), (19, 20, 25, 26, 27, 30, 33, 34, 35, 36, 39, 41, 42), (64, 5),  2);
            Table.States (93).Action_List.Set_Capacity (13);
            Add_Action (Table.States (93), (19, 20, 25, 26, 27, 30, 33, 34, 35, 36, 39, 41, 42), (63, 3),  2);
            Table.States (94).Action_List.Set_Capacity (10);
            Add_Action (Table.States (94), 20, Reduce, (56, 0),  0);
            Add_Action (Table.States (94), 25, (64, 0), 48);
            Add_Action (Table.States (94), 26, (63, 0), 49);
            Add_Action (Table.States (94), 27, (62, 0), 50);
            Add_Action (Table.States (94), 28, (57, 0), 19);
            Add_Action (Table.States (94), 30, Reduce, (56, 0),  0);
            Add_Action (Table.States (94), 36, Reduce, (56, 0),  0);
            Add_Action (Table.States (94), 39, (59, 1), 51);
            Add_Conflict (Table.States (94), 39, (56, 0),  0);
            Add_Action (Table.States (94), 41, (61, 1), 52);
            Add_Action (Table.States (94), 42, Reduce, (56, 0),  0);
            Table.States (94).Goto_List.Set_Capacity (9);
            Add_Goto (Table.States (94), 56, 122);
            Add_Goto (Table.States (94), 57, 20);
            Add_Goto (Table.States (94), 58, 55);
            Add_Goto (Table.States (94), 59, 56);
            Add_Goto (Table.States (94), 60, 57);
            Add_Goto (Table.States (94), 61, 58);
            Add_Goto (Table.States (94), 62, 59);
            Add_Goto (Table.States (94), 63, 60);
            Add_Goto (Table.States (94), 64, 61);
            Table.States (95).Action_List.Set_Capacity (3);
            Add_Action (Table.States (95), 7, (55, 6), 123);
            Add_Action (Table.States (95), 8, (55, 4), 124);
            Add_Action (Table.States (95), 9, (55, 2), 125);
            Table.States (96).Action_List.Set_Capacity (3);
            Add_Action (Table.States (96), (30, 39, 42), (54, 0),  1);
            Table.States (97).Action_List.Set_Capacity (3);
            Add_Action (Table.States (97), (30, 39, 42), (53, 0),  4);
            Table.States (98).Action_List.Set_Capacity (10);
            Add_Action (Table.States (98), 19, (56, 4), 126);
            Add_Action (Table.States (98), 20, Reduce, (56, 2),  2);
            Add_Action (Table.States (98), 25, (64, 0), 48);
            Add_Action (Table.States (98), 26, (63, 0), 49);
            Add_Action (Table.States (98), 27, (62, 0), 50);
            Add_Action (Table.States (98), 30, Reduce, (56, 2),  2);
            Add_Action (Table.States (98), 36, Reduce, (56, 2),  2);
            Add_Action (Table.States (98), 39, (59, 1), 51);
            Add_Conflict (Table.States (98), 39, (56, 2),  2);
            Add_Action (Table.States (98), 41, (61, 1), 52);
            Add_Action (Table.States (98), 42, Reduce, (56, 2),  2);
            Table.States (98).Goto_List.Set_Capacity (5);
            Add_Goto (Table.States (98), 59, 100);
            Add_Goto (Table.States (98), 61, 58);
            Add_Goto (Table.States (98), 62, 59);
            Add_Goto (Table.States (98), 63, 60);
            Add_Goto (Table.States (98), 64, 61);
            Table.States (99).Action_List.Set_Capacity (6);
            Add_Action (Table.States (99), 19, (56, 5), 127);
            Add_Action (Table.States (99), 20, Reduce, (56, 3),  2);
            Add_Action (Table.States (99), 30, Reduce, (56, 3),  2);
            Add_Action (Table.States (99), 36, Reduce, (56, 3),  2);
            Add_Action (Table.States (99), 39, Reduce, (56, 3),  2);
            Add_Action (Table.States (99), 42, Reduce, (56, 3),  2);
            Table.States (100).Action_List.Set_Capacity (13);
            Add_Action (Table.States (100), (19, 20, 25, 26, 27, 30, 33, 34, 35, 36, 39, 41, 42), (60, 0),  2);
            Table.States (101).Action_List.Set_Capacity (3);
            Add_Action (Table.States (101), (30, 39, 42), (53, 3),  4);
            Table.States (102).Action_List.Set_Capacity (1);
            Add_Action (Table.States (102), 39, (57, 0), 128);
            Table.States (103).Action_List.Set_Capacity (5);
            Add_Action (Table.States (103), 20, (55, 1), 94);
            Add_Action (Table.States (103), 30, (55, 2), 95);
            Add_Conflict (Table.States (103), 30, (54, 1),  0);
            Add_Action (Table.States (103), 36, (54, 0), 96);
            Add_Action (Table.States (103), 39, Reduce, (54, 1),  0);
            Add_Action (Table.States (103), 42, Reduce, (54, 1),  0);
            Table.States (103).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (103), 54, 129);
            Table.States (104).Action_List.Set_Capacity (5);
            Add_Action (Table.States (104), 20, (55, 1), 94);
            Add_Action (Table.States (104), 30, (55, 2), 95);
            Add_Conflict (Table.States (104), 30, (54, 1),  0);
            Add_Action (Table.States (104), 36, (54, 0), 96);
            Add_Action (Table.States (104), 39, Reduce, (54, 1),  0);
            Add_Action (Table.States (104), 42, Reduce, (54, 1),  0);
            Table.States (104).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (104), 54, 130);
            Table.States (105).Action_List.Set_Capacity (2);
            Add_Action (Table.States (105), 39, (47, 0), 131);
            Add_Action (Table.States (105), 41, (47, 1), 132);
            Table.States (105).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (105), 47, 133);
            Table.States (106).Action_List.Set_Capacity (2);
            Add_Action (Table.States (106), (13, 20), (46, 1),  3);
            Table.States (107).Action_List.Set_Capacity (2);
            Add_Action (Table.States (107), 39, (47, 0), 131);
            Add_Action (Table.States (107), 41, (47, 1), 132);
            Table.States (107).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (107), 47, 134);
            Table.States (108).Action_List.Set_Capacity (5);
            Add_Action (Table.States (108), (20, 30, 36, 39, 42), (50, 0),  1);
            Table.States (109).Action_List.Set_Capacity (4);
            Add_Action (Table.States (109), 20, (50, 1), 135);
            Add_Action (Table.States (109), 30, Reduce, (48, 15),  5);
            Add_Action (Table.States (109), 39, Reduce, (48, 15),  5);
            Add_Action (Table.States (109), 42, Reduce, (48, 15),  5);
            Table.States (110).Action_List.Set_Capacity (3);
            Add_Action (Table.States (110), (30, 39, 42), (48, 14),  5);
            Table.States (111).Action_List.Set_Capacity (4);
            Add_Action (Table.States (111), 20, (50, 1), 135);
            Add_Action (Table.States (111), 30, Reduce, (48, 13),  5);
            Add_Action (Table.States (111), 39, Reduce, (48, 13),  5);
            Add_Action (Table.States (111), 42, Reduce, (48, 13),  5);
            Table.States (112).Action_List.Set_Capacity (3);
            Add_Action (Table.States (112), (30, 39, 42), (48, 12),  5);
            Table.States (113).Action_List.Set_Capacity (1);
            Add_Action (Table.States (113), 39, (48, 2), 136);
            Table.States (114).Action_List.Set_Capacity (1);
            Add_Action (Table.States (114), 39, (48, 0), 137);
            Table.States (115).Action_List.Set_Capacity (4);
            Add_Action (Table.States (115), 20, (66, 0), 117);
            Add_Action (Table.States (115), 33, Reduce, (65, 0),  2);
            Add_Action (Table.States (115), 34, Reduce, (65, 0),  2);
            Add_Action (Table.States (115), 35, Reduce, (65, 0),  2);
            Table.States (116).Action_List.Set_Capacity (14);
            Add_Action (Table.States (116), 19, Reduce, (64, 0),  3);
            Add_Action (Table.States (116), 20, Reduce, (64, 0),  3);
            Add_Action (Table.States (116), 25, Reduce, (64, 0),  3);
            Add_Action (Table.States (116), 26, Reduce, (64, 0),  3);
            Add_Action (Table.States (116), 27, Reduce, (64, 0),  3);
            Add_Action (Table.States (116), 29, (64, 1), 138);
            Add_Action (Table.States (116), 30, Reduce, (64, 0),  3);
            Add_Action (Table.States (116), 33, Reduce, (64, 0),  3);
            Add_Action (Table.States (116), 34, Reduce, (64, 0),  3);
            Add_Action (Table.States (116), 35, Reduce, (64, 0),  3);
            Add_Action (Table.States (116), 36, Reduce, (64, 0),  3);
            Add_Action (Table.States (116), 39, Reduce, (64, 0),  3);
            Add_Action (Table.States (116), 41, Reduce, (64, 0),  3);
            Add_Action (Table.States (116), 42, Reduce, (64, 0),  3);
         end Subr_2;
         procedure Subr_3
         is begin
            Table.States (117).Action_List.Set_Capacity (5);
            Add_Action (Table.States (117), 25, (64, 0), 48);
            Add_Action (Table.States (117), 26, (63, 0), 49);
            Add_Action (Table.States (117), 27, (62, 0), 50);
            Add_Action (Table.States (117), 39, (59, 1), 51);
            Add_Action (Table.States (117), 41, (61, 1), 52);
            Table.States (117).Goto_List.Set_Capacity (6);
            Add_Goto (Table.States (117), 59, 56);
            Add_Goto (Table.States (117), 60, 139);
            Add_Goto (Table.States (117), 61, 58);
            Add_Goto (Table.States (117), 62, 59);
            Add_Goto (Table.States (117), 63, 60);
            Add_Goto (Table.States (117), 64, 61);
            Table.States (118).Action_List.Set_Capacity (13);
            Add_Action (Table.States (118), (19, 20, 25, 26, 27, 30, 33, 34, 35, 36, 39, 41, 42), (63, 0),  3);
            Table.States (119).Action_List.Set_Capacity (16);
            Add_Action (Table.States (119), 19, Reduce, (62, 0),  3);
            Add_Action (Table.States (119), 20, Reduce, (62, 0),  3);
            Add_Action (Table.States (119), 25, Reduce, (62, 0),  3);
            Add_Action (Table.States (119), 26, Reduce, (62, 0),  3);
            Add_Action (Table.States (119), 27, Reduce, (62, 0),  3);
            Add_Action (Table.States (119), 30, Reduce, (62, 0),  3);
            Add_Action (Table.States (119), 31, (64, 2), 140);
            Add_Action (Table.States (119), 32, (63, 1), 141);
            Add_Action (Table.States (119), 33, Reduce, (62, 0),  3);
            Add_Action (Table.States (119), 34, Reduce, (62, 0),  3);
            Add_Action (Table.States (119), 35, Reduce, (62, 0),  3);
            Add_Action (Table.States (119), 36, Reduce, (62, 0),  3);
            Add_Action (Table.States (119), 37, (64, 3), 142);
            Add_Action (Table.States (119), 39, Reduce, (62, 0),  3);
            Add_Action (Table.States (119), 41, Reduce, (62, 0),  3);
            Add_Action (Table.States (119), 42, Reduce, (62, 0),  3);
            Table.States (120).Action_List.Set_Capacity (16);
            Add_Action (Table.States (120), 19, Reduce, (61, 0),  1);
            Add_Action (Table.States (120), 20, Reduce, (61, 0),  1);
            Add_Action (Table.States (120), 25, Reduce, (61, 0),  1);
            Add_Action (Table.States (120), 26, Reduce, (61, 0),  1);
            Add_Action (Table.States (120), 27, Reduce, (61, 0),  1);
            Add_Action (Table.States (120), 30, Reduce, (61, 0),  1);
            Add_Action (Table.States (120), 31, (64, 4), 90);
            Add_Action (Table.States (120), 32, (63, 2), 91);
            Add_Action (Table.States (120), 33, Reduce, (61, 0),  1);
            Add_Action (Table.States (120), 34, Reduce, (61, 0),  1);
            Add_Action (Table.States (120), 35, Reduce, (61, 0),  1);
            Add_Action (Table.States (120), 36, Reduce, (61, 0),  1);
            Add_Action (Table.States (120), 37, (64, 5), 92);
            Add_Action (Table.States (120), 39, Reduce, (61, 0),  1);
            Add_Action (Table.States (120), 41, Reduce, (61, 0),  1);
            Add_Action (Table.States (120), 42, Reduce, (61, 0),  1);
            Table.States (121).Action_List.Set_Capacity (13);
            Add_Action (Table.States (121), (19, 20, 25, 26, 27, 30, 33, 34, 35, 36, 39, 41, 42), (59, 1),  3);
            Table.States (122).Action_List.Set_Capacity (5);
            Add_Action (Table.States (122), (20, 30, 36, 39, 42), (55, 1),  3);
            Table.States (123).Action_List.Set_Capacity (1);
            Add_Action (Table.States (123), 9, (55, 6), 143);
            Table.States (124).Action_List.Set_Capacity (1);
            Add_Action (Table.States (124), 39, (55, 4), 144);
            Table.States (125).Action_List.Set_Capacity (1);
            Add_Action (Table.States (125), 39, (55, 2), 145);
            Table.States (126).Action_List.Set_Capacity (6);
            Add_Action (Table.States (126), 19, (56, 6), 146);
            Add_Action (Table.States (126), 20, Reduce, (56, 4),  3);
            Add_Action (Table.States (126), 30, Reduce, (56, 4),  3);
            Add_Action (Table.States (126), 36, Reduce, (56, 4),  3);
            Add_Action (Table.States (126), 39, Reduce, (56, 4),  3);
            Add_Action (Table.States (126), 42, Reduce, (56, 4),  3);
            Table.States (127).Action_List.Set_Capacity (5);
            Add_Action (Table.States (127), (20, 30, 36, 39, 42), (56, 5),  3);
            Table.States (128).Action_List.Set_Capacity (1);
            Add_Action (Table.States (128), 24, (57, 0), 147);
            Table.States (129).Action_List.Set_Capacity (3);
            Add_Action (Table.States (129), (30, 39, 42), (53, 1),  5);
            Table.States (130).Action_List.Set_Capacity (3);
            Add_Action (Table.States (130), (30, 39, 42), (53, 2),  5);
            Table.States (131).Action_List.Set_Capacity (4);
            Add_Action (Table.States (131), (21, 30, 39, 42), (47, 0),  1);
            Table.States (132).Action_List.Set_Capacity (4);
            Add_Action (Table.States (132), (21, 30, 39, 42), (47, 1),  1);
            Table.States (133).Action_List.Set_Capacity (3);
            Add_Action (Table.States (133), (30, 39, 42), (48, 8),  6);
            Table.States (134).Action_List.Set_Capacity (1);
            Add_Action (Table.States (134), 21, (48, 9), 148);
            Table.States (135).Action_List.Set_Capacity (1);
            Add_Action (Table.States (135), 39, (50, 1), 149);
            Table.States (136).Action_List.Set_Capacity (6);
            Add_Action (Table.States (136), 18, (44, 0), 40);
            Add_Action (Table.States (136), 30, Reduce, (48, 4),  6);
            Add_Action (Table.States (136), 39, Reduce, (48, 4),  6);
            Add_Action (Table.States (136), 40, (44, 1), 43);
            Add_Action (Table.States (136), 41, (44, 2), 44);
            Add_Action (Table.States (136), 42, Reduce, (48, 4),  6);
            Table.States (136).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (136), 44, 150);
            Table.States (137).Action_List.Set_Capacity (3);
            Add_Action (Table.States (137), 18, (44, 0), 40);
            Add_Action (Table.States (137), 40, (44, 1), 43);
            Add_Action (Table.States (137), 41, (44, 2), 44);
            Table.States (137).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (137), 44, 151);
            Table.States (138).Action_List.Set_Capacity (13);
            Add_Action (Table.States (138), (19, 20, 25, 26, 27, 30, 33, 34, 35, 36, 39, 41, 42), (64, 1),  4);
            Table.States (139).Action_List.Set_Capacity (9);
            Add_Action (Table.States (139), 20, Reduce, (66, 0),  3);
            Add_Action (Table.States (139), 25, (64, 0), 48);
            Add_Action (Table.States (139), 26, (63, 0), 49);
            Add_Action (Table.States (139), 27, (62, 0), 50);
            Add_Action (Table.States (139), 33, Reduce, (66, 0),  3);
            Add_Action (Table.States (139), 34, Reduce, (66, 0),  3);
            Add_Action (Table.States (139), 35, Reduce, (66, 0),  3);
            Add_Action (Table.States (139), 39, (59, 1), 51);
            Add_Action (Table.States (139), 41, (61, 1), 52);
            Table.States (139).Goto_List.Set_Capacity (5);
            Add_Goto (Table.States (139), 59, 100);
            Add_Goto (Table.States (139), 61, 58);
            Add_Goto (Table.States (139), 62, 59);
            Add_Goto (Table.States (139), 63, 60);
            Add_Goto (Table.States (139), 64, 61);
            Table.States (140).Action_List.Set_Capacity (13);
            Add_Action (Table.States (140), (19, 20, 25, 26, 27, 30, 33, 34, 35, 36, 39, 41, 42), (64, 2),  4);
            Table.States (141).Action_List.Set_Capacity (13);
            Add_Action (Table.States (141), (19, 20, 25, 26, 27, 30, 33, 34, 35, 36, 39, 41, 42), (63, 1),  4);
            Table.States (142).Action_List.Set_Capacity (13);
            Add_Action (Table.States (142), (19, 20, 25, 26, 27, 30, 33, 34, 35, 36, 39, 41, 42), (64, 3),  4);
            Table.States (143).Action_List.Set_Capacity (5);
            Add_Action (Table.States (143), (20, 30, 36, 39, 42), (55, 6),  4);
            Table.States (144).Action_List.Set_Capacity (2);
            Add_Action (Table.States (144), 10, (55, 5), 152);
            Add_Action (Table.States (144), 23, (55, 4), 153);
            Table.States (145).Action_List.Set_Capacity (2);
            Add_Action (Table.States (145), 10, (55, 3), 154);
            Add_Action (Table.States (145), 23, (55, 2), 155);
            Table.States (146).Action_List.Set_Capacity (5);
            Add_Action (Table.States (146), (20, 30, 36, 39, 42), (56, 6),  4);
            Table.States (147).Action_List.Set_Capacity (8);
            Add_Action (Table.States (147), (21, 22, 25, 26, 27, 28, 39, 41), (57, 0),  5);
            Table.States (148).Action_List.Set_Capacity (1);
            Add_Action (Table.States (148), 39, (48, 9), 156);
            Table.States (149).Action_List.Set_Capacity (5);
            Add_Action (Table.States (149), (20, 30, 36, 39, 42), (50, 1),  3);
            Table.States (150).Action_List.Set_Capacity (6);
            Add_Action (Table.States (150), 18, (44, 0), 40);
            Add_Action (Table.States (150), 30, Reduce, (48, 3),  7);
            Add_Action (Table.States (150), 39, Reduce, (48, 3),  7);
            Add_Action (Table.States (150), 40, (44, 1), 43);
            Add_Action (Table.States (150), 41, (44, 2), 44);
            Add_Action (Table.States (150), 42, Reduce, (48, 3),  7);
            Table.States (150).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (150), 44, 157);
            Table.States (151).Action_List.Set_Capacity (6);
            Add_Action (Table.States (151), 18, (44, 0), 40);
            Add_Action (Table.States (151), 30, Reduce, (48, 1),  7);
            Add_Action (Table.States (151), 39, Reduce, (48, 1),  7);
            Add_Action (Table.States (151), 40, (44, 1), 43);
            Add_Action (Table.States (151), 41, (44, 2), 44);
            Add_Action (Table.States (151), 42, Reduce, (48, 1),  7);
            Table.States (151).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (151), 44, 158);
            Table.States (152).Action_List.Set_Capacity (1);
            Add_Action (Table.States (152), 39, (50, 0), 108);
            Table.States (152).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (152), 50, 159);
            Table.States (153).Action_List.Set_Capacity (1);
            Add_Action (Table.States (153), 39, (55, 4), 160);
            Table.States (154).Action_List.Set_Capacity (1);
            Add_Action (Table.States (154), 39, (50, 0), 108);
            Table.States (154).Goto_List.Set_Capacity (1);
            Add_Goto (Table.States (154), 50, 161);
            Table.States (155).Action_List.Set_Capacity (1);
            Add_Action (Table.States (155), 39, (55, 2), 162);
            Table.States (156).Action_List.Set_Capacity (3);
            Add_Action (Table.States (156), (30, 39, 42), (48, 9),  8);
            Table.States (157).Action_List.Set_Capacity (3);
            Add_Action (Table.States (157), (30, 39, 42), (48, 2),  8);
            Table.States (158).Action_List.Set_Capacity (3);
            Add_Action (Table.States (158), (30, 39, 42), (48, 0),  8);
            Table.States (159).Action_List.Set_Capacity (5);
            Add_Action (Table.States (159), 20, (50, 1), 135);
            Add_Conflict (Table.States (159), 20, (55, 5),  6);
            Add_Action (Table.States (159), 30, Reduce, (55, 5),  6);
            Add_Action (Table.States (159), 36, Reduce, (55, 5),  6);
            Add_Action (Table.States (159), 39, Reduce, (55, 5),  6);
            Add_Action (Table.States (159), 42, Reduce, (55, 5),  6);
            Table.States (160).Action_List.Set_Capacity (5);
            Add_Action (Table.States (160), (20, 30, 36, 39, 42), (55, 4),  6);
            Table.States (161).Action_List.Set_Capacity (5);
            Add_Action (Table.States (161), 20, (50, 1), 135);
            Add_Conflict (Table.States (161), 20, (55, 3),  6);
            Add_Action (Table.States (161), 30, Reduce, (55, 3),  6);
            Add_Action (Table.States (161), 36, Reduce, (55, 3),  6);
            Add_Action (Table.States (161), 39, Reduce, (55, 3),  6);
            Add_Action (Table.States (161), 42, Reduce, (55, 3),  6);
            Table.States (162).Action_List.Set_Capacity (5);
            Add_Action (Table.States (162), (20, 30, 36, 39, 42), (55, 2),  6);
         end Subr_3;
      begin
         Subr_1;
         Subr_2;
         Subr_3;
         Table.Error_Action := new Parse_Action_Node'((Verb => Error, others => <>), null);
      end;

      Table.Max_Parallel := 15;
      return Table;
   end Create_Parse_Table;

   function Create_Productions return WisiToken.Syntax_Trees.Production_Info_Trees.Vector
   is begin
      return Result : WisiToken.Syntax_Trees.Production_Info_Trees.Vector do
         Result.Set_First_Last (43, 68);
         Result (48).RHSs.Set_First_Last (0, 16);
         Result (48).RHSs (0).In_Parse_Action := null;
         Result (48).RHSs (0).Post_Parse_Action := declaration_0'Access;
         Result (48).RHSs (1).In_Parse_Action := null;
         Result (48).RHSs (1).Post_Parse_Action := declaration_1'Access;
         Result (48).RHSs (2).In_Parse_Action := null;
         Result (48).RHSs (2).Post_Parse_Action := declaration_2'Access;
         Result (48).RHSs (3).In_Parse_Action := null;
         Result (48).RHSs (3).Post_Parse_Action := declaration_3'Access;
         Result (48).RHSs (4).In_Parse_Action := null;
         Result (48).RHSs (4).Post_Parse_Action := declaration_4'Access;
         Result (48).RHSs (5).In_Parse_Action := null;
         Result (48).RHSs (5).Post_Parse_Action := declaration_5'Access;
         Result (48).RHSs (6).In_Parse_Action := null;
         Result (48).RHSs (6).Post_Parse_Action := declaration_6'Access;
         Result (48).RHSs (7).In_Parse_Action := null;
         Result (48).RHSs (7).Post_Parse_Action := declaration_7'Access;
         Result (48).RHSs (8).In_Parse_Action := null;
         Result (48).RHSs (8).Post_Parse_Action := declaration_8'Access;
         Result (48).RHSs (9).In_Parse_Action := null;
         Result (48).RHSs (9).Post_Parse_Action := declaration_9'Access;
         Result (48).RHSs (10).In_Parse_Action := null;
         Result (48).RHSs (10).Post_Parse_Action := declaration_10'Access;
         Result (48).RHSs (11).In_Parse_Action := null;
         Result (48).RHSs (11).Post_Parse_Action := declaration_11'Access;
         Result (48).RHSs (12).In_Parse_Action := null;
         Result (48).RHSs (12).Post_Parse_Action := declaration_12'Access;
         Result (48).RHSs (13).In_Parse_Action := null;
         Result (48).RHSs (13).Post_Parse_Action := declaration_13'Access;
         Result (48).RHSs (14).In_Parse_Action := null;
         Result (48).RHSs (14).Post_Parse_Action := declaration_14'Access;
         Result (48).RHSs (15).In_Parse_Action := null;
         Result (48).RHSs (15).Post_Parse_Action := declaration_15'Access;
         Result (48).RHSs (16).In_Parse_Action := null;
         Result (48).RHSs (16).Post_Parse_Action := declaration_16'Access;
         Result (53).RHSs.Set_First_Last (0, 3);
         Result (53).RHSs (0).In_Parse_Action := null;
         Result (53).RHSs (0).Post_Parse_Action := nonterminal_0'Access;
         Result (53).RHSs (1).In_Parse_Action := null;
         Result (53).RHSs (1).Post_Parse_Action := nonterminal_1'Access;
         Result (53).RHSs (2).In_Parse_Action := null;
         Result (53).RHSs (2).Post_Parse_Action := nonterminal_2'Access;
         Result (53).RHSs (3).In_Parse_Action := null;
         Result (53).RHSs (3).Post_Parse_Action := nonterminal_3'Access;
         Result (61).RHSs.Set_First_Last (0, 4);
         Result (61).RHSs (0).In_Parse_Action := null;
         Result (61).RHSs (0).Post_Parse_Action := null;
         Result (61).RHSs (1).In_Parse_Action := null;
         Result (61).RHSs (1).Post_Parse_Action := rhs_item_1'Access;
         Result (61).RHSs (2).In_Parse_Action := null;
         Result (61).RHSs (2).Post_Parse_Action := rhs_item_2'Access;
         Result (61).RHSs (3).In_Parse_Action := null;
         Result (61).RHSs (3).Post_Parse_Action := rhs_item_3'Access;
         Result (61).RHSs (4).In_Parse_Action := null;
         Result (61).RHSs (4).Post_Parse_Action := rhs_item_4'Access;
         Result (63).RHSs.Set_First_Last (0, 3);
         Result (63).RHSs (0).In_Parse_Action := null;
         Result (63).RHSs (0).Post_Parse_Action := null;
         Result (63).RHSs (1).In_Parse_Action := null;
         Result (63).RHSs (1).Post_Parse_Action := null;
         Result (63).RHSs (2).In_Parse_Action := null;
         Result (63).RHSs (2).Post_Parse_Action := null;
         Result (63).RHSs (3).In_Parse_Action := null;
         Result (63).RHSs (3).Post_Parse_Action := rhs_optional_item_3'Access;
      end return;
   end Create_Productions;

   function Create_Parser
     (Trace      : in WisiToken.Trace_Access;
      User_Data  : in WisiToken.Syntax_Trees.User_Data_Access)
     return WisiToken.Parse.LR.Parser_No_Recover.Parser
   is begin
      return Parser : WisiToken.Parse.LR.Parser_No_Recover.Parser do
         Parser.Tree.Lexer := Lexer.New_Lexer (Trace, Wisitoken_Grammar_Actions.Descriptor'Access);
         Parser.Productions := Create_Productions;
         Parser.User_Data := User_Data;
         Parser.Table := Create_Parse_Table;
      end return;
   end Create_Parser;
end Wisitoken_Grammar_Main;
