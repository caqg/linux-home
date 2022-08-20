--  generated parser support file.
--  command line: wisitoken-bnf-generate.exe  --generate LALR Ada re2c wisitoken_grammar.wy
--

--  Copyright (C) 2017 - 2019 Free Software Foundation, Inc.
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
--  along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

with Wisitoken_Grammar_Actions; use Wisitoken_Grammar_Actions;
with WisiToken.Lexer.re2c;
with wisitoken_grammar_re2c_c;
package body Wisitoken_Grammar_Main is

   package Lexer is new WisiToken.Lexer.re2c
     (wisitoken_grammar_re2c_c.New_Lexer,
      wisitoken_grammar_re2c_c.Free_Lexer,
      wisitoken_grammar_re2c_c.Reset_Lexer,
      wisitoken_grammar_re2c_c.Next_Token);

   procedure Create_Parser
     (Parser                         :    out WisiToken.Parse.LR.Parser_No_Recover.Parser;
      Trace                        : not null access WisiToken.Trace'Class;
      User_Data                    : in     WisiToken.Syntax_Trees.User_Data_Access)
   is
      use WisiToken.Parse.LR;
      Table : constant Parse_Table_Ptr := new Parse_Table
        (State_First       => 0,
         State_Last        => 102,
         First_Terminal    => 3,
         Last_Terminal     => 36,
         First_Nonterminal => 37,
         Last_Nonterminal  => 56);
   begin
      declare
         procedure Subr_1
         is begin
            Add_Action (Table.States (0), 23, 1);
            Add_Action (Table.States (0), 33, 2);
            Add_Error (Table.States (0));
            Add_Goto (Table.States (0), 38, 3);
            Add_Goto (Table.States (0), 43, 4);
            Add_Goto (Table.States (0), 55, 5);
            Add_Goto (Table.States (0), 56, 6);
            Add_Action (Table.States (1), 3, 7);
            Add_Action (Table.States (1), 4, 8);
            Add_Action (Table.States (1), 5, 9);
            Add_Action (Table.States (1), 6, 10);
            Add_Action (Table.States (1), 7, 11);
            Add_Action (Table.States (1), 8, 12);
            Add_Action (Table.States (1), 33, 13);
            Add_Error (Table.States (1));
            Add_Goto (Table.States (1), 39, 14);
            Add_Action (Table.States (2), 13, 15);
            Add_Action (Table.States (2), 14, 16);
            Add_Error (Table.States (2));
            Add_Action (Table.States (3), (23, 33, 36), (55, 0), 1, null, null);
            Add_Action (Table.States (4), (23, 33, 36), (55, 1), 1, null, null);
            Add_Action (Table.States (5), (23, 33, 36), (56, 0), 1, null, null);
            Add_Action (Table.States (6), 23, 1);
            Add_Action (Table.States (6), 33, 2);
            Add_Action (Table.States (6), 36, Accept_It, (37, 0), 1, null, null);
            Add_Error (Table.States (6));
            Add_Goto (Table.States (6), 38, 3);
            Add_Goto (Table.States (6), 43, 4);
            Add_Goto (Table.States (6), 55, 17);
            Add_Action (Table.States (7), 33, 18);
            Add_Error (Table.States (7));
            Add_Goto (Table.States (7), 40, 19);
            Add_Action (Table.States (8), 5, 20);
            Add_Error (Table.States (8));
            Add_Action (Table.States (9), 33, 21);
            Add_Error (Table.States (9));
            Add_Action (Table.States (10), (1 =>  33), (39, 0), 1, null, null);
            Add_Action (Table.States (11), 21, 22);
            Add_Error (Table.States (11));
            Add_Action (Table.States (12), 21, 23);
            Add_Error (Table.States (12));
            Add_Action (Table.States (13), 8, 24);
            Add_Action (Table.States (13), 10, 25);
            Add_Action (Table.States (13), 15, 26);
            Add_Action (Table.States (13), 16, 27);
            Add_Action (Table.States (13), 20, 28);
            Add_Action (Table.States (13), 23, Reduce, (38, 3), 2, declaration_3'Access, null);
            Add_Action (Table.States (13), 28, 29);
            Add_Action (Table.States (13), 30, 30);
            Add_Action (Table.States (13), 32, 31);
            Add_Action (Table.States (13), 33, 32);
            Add_Conflict (Table.States (13), 33, (38, 3), 2, declaration_3'Access, null);
            Add_Action (Table.States (13), 34, 33);
            Add_Action (Table.States (13), 35, 34);
            Add_Action (Table.States (13), 36, Reduce, (38, 3), 2, declaration_3'Access, null);
            Add_Error (Table.States (13));
            Add_Goto (Table.States (13), 41, 35);
            Add_Goto (Table.States (13), 42, 36);
            Add_Action (Table.States (14), 33, 37);
            Add_Error (Table.States (14));
            Add_Action (Table.States (15), 12, Reduce, (46, 0), 0, null, null);
            Add_Action (Table.States (15), 18, 38);
            Add_Action (Table.States (15), 19, 39);
            Add_Action (Table.States (15), 20, 40);
            Add_Action (Table.States (15), 21, 41);
            Add_Action (Table.States (15), 23, Reduce, (46, 0), 0, null, null);
            Add_Action (Table.States (15), 29, Reduce, (46, 0), 0, null, null);
            Add_Action (Table.States (15), 33, 42);
            Add_Conflict (Table.States (15), 33, (46, 0), 0, null, null);
            Add_Action (Table.States (15), 35, 43);
            Add_Action (Table.States (15), 36, Reduce, (46, 0), 0, null, null);
            Add_Error (Table.States (15));
            Add_Goto (Table.States (15), 45, 44);
            Add_Goto (Table.States (15), 46, 45);
            Add_Goto (Table.States (15), 47, 46);
            Add_Goto (Table.States (15), 48, 47);
            Add_Goto (Table.States (15), 49, 48);
            Add_Goto (Table.States (15), 50, 49);
            Add_Goto (Table.States (15), 51, 50);
            Add_Goto (Table.States (15), 52, 51);
            Add_Goto (Table.States (15), 53, 52);
            Add_Action (Table.States (16), 12, Reduce, (46, 0), 0, null, null);
            Add_Action (Table.States (16), 18, 38);
            Add_Action (Table.States (16), 19, 39);
            Add_Action (Table.States (16), 20, 40);
            Add_Action (Table.States (16), 21, 41);
            Add_Action (Table.States (16), 23, Reduce, (46, 0), 0, null, null);
            Add_Action (Table.States (16), 29, Reduce, (46, 0), 0, null, null);
            Add_Action (Table.States (16), 33, 42);
            Add_Conflict (Table.States (16), 33, (46, 0), 0, null, null);
            Add_Action (Table.States (16), 35, 43);
            Add_Action (Table.States (16), 36, Reduce, (46, 0), 0, null, null);
            Add_Error (Table.States (16));
            Add_Goto (Table.States (16), 45, 53);
            Add_Goto (Table.States (16), 46, 45);
            Add_Goto (Table.States (16), 47, 46);
            Add_Goto (Table.States (16), 48, 47);
            Add_Goto (Table.States (16), 49, 48);
            Add_Goto (Table.States (16), 50, 49);
            Add_Goto (Table.States (16), 51, 50);
            Add_Goto (Table.States (16), 52, 51);
            Add_Goto (Table.States (16), 53, 52);
            Add_Action (Table.States (17), (23, 33, 36), (56, 1), 2, null, null);
            Add_Action (Table.States (18), (9, 33), (40, 0), 1, null, null);
            Add_Action (Table.States (19), 9, 54);
            Add_Action (Table.States (19), 33, 55);
            Add_Error (Table.States (19));
            Add_Action (Table.States (20), (23, 33, 36), (38, 5), 3, declaration_5'Access, null);
            Add_Action (Table.States (21), 16, 56);
            Add_Error (Table.States (21));
            Add_Action (Table.States (22), 33, 57);
            Add_Error (Table.States (22));
            Add_Action (Table.States (23), 33, 58);
            Add_Error (Table.States (23));
            Add_Action (Table.States (24), (8, 10, 15, 16, 20, 23, 28, 30, 32, 33, 34, 35, 36), (42, 10), 1, null,
            null);
            Add_Action (Table.States (25), (8, 10, 15, 16, 20, 23, 28, 30, 32, 33, 34, 35, 36), (42, 5), 1, null,
            null);
            Add_Action (Table.States (26), (8, 10, 15, 16, 20, 23, 28, 30, 32, 33, 34, 35, 36), (42, 0), 1, null,
            null);
            Add_Action (Table.States (27), (8, 10, 15, 16, 20, 23, 28, 30, 32, 33, 34, 35, 36), (42, 2), 1, null,
            null);
            Add_Action (Table.States (28), (8, 10, 15, 16, 20, 23, 28, 30, 32, 33, 34, 35, 36), (42, 3), 1, null,
            null);
            Add_Action (Table.States (29), (8, 10, 15, 16, 20, 23, 28, 30, 32, 33, 34, 35, 36), (42, 6), 1, null,
            null);
            Add_Action (Table.States (30), (8, 10, 15, 16, 20, 23, 28, 30, 32, 33, 34, 35, 36), (42, 7), 1, null,
            null);
            Add_Action (Table.States (31), (8, 10, 15, 16, 20, 23, 28, 30, 32, 33, 34, 35, 36), (42, 4), 1, null,
            null);
            Add_Action (Table.States (32), (8, 10, 15, 16, 20, 23, 28, 30, 32, 33, 34, 35, 36), (42, 1), 1, null,
            null);
            Add_Action (Table.States (33), (8, 10, 15, 16, 20, 23, 28, 30, 32, 33, 34, 35, 36), (42, 8), 1, null,
            null);
            Add_Action (Table.States (34), (8, 10, 15, 16, 20, 23, 28, 30, 32, 33, 34, 35, 36), (42, 9), 1, null,
            null);
            Add_Action (Table.States (35), 8, 24);
            Add_Action (Table.States (35), 10, 25);
            Add_Action (Table.States (35), 15, 26);
            Add_Action (Table.States (35), 16, 27);
            Add_Action (Table.States (35), 20, 28);
            Add_Action (Table.States (35), 23, Reduce, (38, 2), 3, declaration_2'Access, null);
            Add_Action (Table.States (35), 28, 29);
            Add_Action (Table.States (35), 30, 30);
            Add_Action (Table.States (35), 32, 31);
            Add_Action (Table.States (35), 33, 32);
            Add_Conflict (Table.States (35), 33, (38, 2), 3, declaration_2'Access, null);
            Add_Action (Table.States (35), 34, 33);
            Add_Action (Table.States (35), 35, 34);
            Add_Action (Table.States (35), 36, Reduce, (38, 2), 3, declaration_2'Access, null);
            Add_Error (Table.States (35));
            Add_Goto (Table.States (35), 42, 59);
            Add_Action (Table.States (36), (8, 10, 15, 16, 20, 23, 28, 30, 32, 33, 34, 35, 36), (41, 0), 1, null,
            null);
            Add_Action (Table.States (37), 8, 24);
            Add_Action (Table.States (37), 10, 25);
            Add_Action (Table.States (37), 15, 26);
            Add_Action (Table.States (37), 16, 27);
            Add_Action (Table.States (37), 20, 28);
            Add_Action (Table.States (37), 28, 29);
            Add_Action (Table.States (37), 30, 30);
            Add_Action (Table.States (37), 32, 31);
            Add_Action (Table.States (37), 33, 32);
            Add_Action (Table.States (37), 34, 33);
            Add_Action (Table.States (37), 35, 34);
            Add_Error (Table.States (37));
            Add_Goto (Table.States (37), 41, 60);
            Add_Goto (Table.States (37), 42, 36);
            Add_Action (Table.States (38), 18, 38);
            Add_Action (Table.States (38), 19, 39);
            Add_Action (Table.States (38), 20, 40);
            Add_Action (Table.States (38), 21, 41);
            Add_Action (Table.States (38), 33, 42);
            Add_Action (Table.States (38), 35, 43);
            Add_Error (Table.States (38));
            Add_Goto (Table.States (38), 47, 46);
            Add_Goto (Table.States (38), 48, 47);
            Add_Goto (Table.States (38), 49, 61);
            Add_Goto (Table.States (38), 50, 49);
            Add_Goto (Table.States (38), 51, 50);
            Add_Goto (Table.States (38), 52, 51);
            Add_Goto (Table.States (38), 53, 52);
            Add_Goto (Table.States (38), 54, 62);
            Add_Action (Table.States (39), 18, 38);
            Add_Action (Table.States (39), 19, 39);
            Add_Action (Table.States (39), 20, 40);
            Add_Action (Table.States (39), 21, 41);
            Add_Action (Table.States (39), 33, 42);
            Add_Action (Table.States (39), 35, 43);
            Add_Error (Table.States (39));
            Add_Goto (Table.States (39), 47, 46);
            Add_Goto (Table.States (39), 48, 47);
            Add_Goto (Table.States (39), 49, 61);
            Add_Goto (Table.States (39), 50, 49);
            Add_Goto (Table.States (39), 51, 50);
            Add_Goto (Table.States (39), 52, 51);
            Add_Goto (Table.States (39), 53, 52);
            Add_Goto (Table.States (39), 54, 63);
            Add_Action (Table.States (40), 18, 38);
            Add_Action (Table.States (40), 19, 39);
            Add_Action (Table.States (40), 20, 40);
            Add_Action (Table.States (40), 21, 41);
            Add_Action (Table.States (40), 33, 42);
            Add_Action (Table.States (40), 35, 43);
            Add_Error (Table.States (40));
            Add_Goto (Table.States (40), 47, 46);
            Add_Goto (Table.States (40), 48, 47);
            Add_Goto (Table.States (40), 49, 61);
            Add_Goto (Table.States (40), 50, 49);
            Add_Goto (Table.States (40), 51, 50);
            Add_Goto (Table.States (40), 52, 51);
            Add_Goto (Table.States (40), 53, 52);
            Add_Goto (Table.States (40), 54, 64);
            Add_Action (Table.States (41), 33, 65);
            Add_Error (Table.States (41));
            Add_Action (Table.States (42), 11, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (42), 12, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (42), 16, 66);
            Add_Action (Table.States (42), 18, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (42), 19, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (42), 20, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (42), 21, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (42), 23, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (42), 24, 67);
            Add_Action (Table.States (42), 25, 68);
            Add_Action (Table.States (42), 26, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (42), 27, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (42), 28, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (42), 29, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (42), 31, 69);
            Add_Action (Table.States (42), 33, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (42), 35, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (42), 36, Reduce, (50, 0), 1, null, null);
            Add_Error (Table.States (42));
            Add_Action (Table.States (43), 11, Reduce, (50, 1), 1, rhs_item_1'Access, null);
            Add_Action (Table.States (43), 12, Reduce, (50, 1), 1, rhs_item_1'Access, null);
            Add_Action (Table.States (43), 18, Reduce, (50, 1), 1, rhs_item_1'Access, null);
            Add_Action (Table.States (43), 19, Reduce, (50, 1), 1, rhs_item_1'Access, null);
            Add_Action (Table.States (43), 20, Reduce, (50, 1), 1, rhs_item_1'Access, null);
            Add_Action (Table.States (43), 21, Reduce, (50, 1), 1, rhs_item_1'Access, null);
            Add_Action (Table.States (43), 23, Reduce, (50, 1), 1, rhs_item_1'Access, null);
            Add_Action (Table.States (43), 25, 70);
            Add_Action (Table.States (43), 26, Reduce, (50, 1), 1, rhs_item_1'Access, null);
            Add_Action (Table.States (43), 27, Reduce, (50, 1), 1, rhs_item_1'Access, null);
            Add_Action (Table.States (43), 28, Reduce, (50, 1), 1, rhs_item_1'Access, null);
            Add_Action (Table.States (43), 29, Reduce, (50, 1), 1, rhs_item_1'Access, null);
            Add_Action (Table.States (43), 33, Reduce, (50, 1), 1, rhs_item_1'Access, null);
            Add_Action (Table.States (43), 35, Reduce, (50, 1), 1, rhs_item_1'Access, null);
            Add_Action (Table.States (43), 36, Reduce, (50, 1), 1, rhs_item_1'Access, null);
            Add_Error (Table.States (43));
            Add_Action (Table.States (44), 12, 71);
            Add_Action (Table.States (44), 23, 72);
            Add_Conflict (Table.States (44), 23, (44, 1), 0, null, null);
            Add_Action (Table.States (44), 29, 73);
            Add_Action (Table.States (44), 33, Reduce, (44, 1), 0, null, null);
            Add_Action (Table.States (44), 36, Reduce, (44, 1), 0, null, null);
            Add_Error (Table.States (44));
            Add_Goto (Table.States (44), 44, 74);
            Add_Action (Table.States (45), (12, 23, 29, 33, 36), (45, 0), 1, null, null);
            Add_Action (Table.States (46), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (50, 2), 1,
            rhs_item_2'Access, null);
            Add_Action (Table.States (47), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (49, 0), 1, null,
            null);
            Add_Action (Table.States (48), 11, 75);
            Add_Action (Table.States (48), 12, Reduce, (46, 1), 1, null, null);
            Add_Action (Table.States (48), 18, 38);
            Add_Action (Table.States (48), 19, 39);
            Add_Action (Table.States (48), 20, 40);
            Add_Action (Table.States (48), 21, 41);
            Add_Action (Table.States (48), 23, Reduce, (46, 1), 1, null, null);
            Add_Action (Table.States (48), 29, Reduce, (46, 1), 1, null, null);
            Add_Action (Table.States (48), 33, 42);
            Add_Conflict (Table.States (48), 33, (46, 1), 1, null, null);
            Add_Action (Table.States (48), 35, 43);
            Add_Action (Table.States (48), 36, Reduce, (46, 1), 1, null, null);
            Add_Error (Table.States (48));
            Add_Goto (Table.States (48), 47, 46);
            Add_Goto (Table.States (48), 48, 76);
            Add_Goto (Table.States (48), 50, 49);
            Add_Goto (Table.States (48), 51, 50);
            Add_Goto (Table.States (48), 52, 51);
            Add_Goto (Table.States (48), 53, 52);
            Add_Action (Table.States (49), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (48, 0), 1, null,
            null);
            Add_Action (Table.States (50), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (50, 5), 1,
            rhs_item_5'Access, null);
            Add_Action (Table.States (51), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (50, 3), 1,
            rhs_item_3'Access, null);
            Add_Action (Table.States (52), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (50, 4), 1,
            rhs_item_4'Access, null);
            Add_Action (Table.States (53), 12, 71);
            Add_Action (Table.States (53), 23, 72);
            Add_Conflict (Table.States (53), 23, (44, 1), 0, null, null);
            Add_Action (Table.States (53), 29, 73);
            Add_Action (Table.States (53), 33, Reduce, (44, 1), 0, null, null);
            Add_Action (Table.States (53), 36, Reduce, (44, 1), 0, null, null);
            Add_Error (Table.States (53));
            Add_Goto (Table.States (53), 44, 77);
            Add_Action (Table.States (54), (23, 33, 36), (38, 1), 4, declaration_1'Access, null);
            Add_Action (Table.States (55), (9, 33), (40, 1), 2, null, null);
            Add_Action (Table.States (56), 33, 78);
            Add_Error (Table.States (56));
            Add_Action (Table.States (57), 17, 79);
            Add_Error (Table.States (57));
            Add_Action (Table.States (58), 17, 80);
            Add_Error (Table.States (58));
            Add_Action (Table.States (59), (8, 10, 15, 16, 20, 23, 28, 30, 32, 33, 34, 35, 36), (41, 1), 2, null,
            null);
            Add_Action (Table.States (60), 8, 24);
            Add_Action (Table.States (60), 10, 25);
            Add_Action (Table.States (60), 15, 26);
            Add_Action (Table.States (60), 16, 27);
            Add_Action (Table.States (60), 20, 28);
            Add_Action (Table.States (60), 23, Reduce, (38, 0), 4, declaration_0'Access, null);
            Add_Action (Table.States (60), 28, 29);
            Add_Action (Table.States (60), 30, 30);
            Add_Action (Table.States (60), 32, 31);
            Add_Action (Table.States (60), 33, 32);
            Add_Conflict (Table.States (60), 33, (38, 0), 4, declaration_0'Access, null);
            Add_Action (Table.States (60), 34, 33);
            Add_Action (Table.States (60), 35, 34);
            Add_Action (Table.States (60), 36, Reduce, (38, 0), 4, declaration_0'Access, null);
            Add_Error (Table.States (60));
            Add_Goto (Table.States (60), 42, 59);
            Add_Action (Table.States (61), 12, Reduce, (54, 0), 1, null, null);
            Add_Action (Table.States (61), 18, 38);
            Add_Action (Table.States (61), 19, 39);
            Add_Action (Table.States (61), 20, 40);
            Add_Action (Table.States (61), 21, 41);
            Add_Action (Table.States (61), 26, Reduce, (54, 0), 1, null, null);
            Add_Action (Table.States (61), 27, Reduce, (54, 0), 1, null, null);
            Add_Action (Table.States (61), 28, Reduce, (54, 0), 1, null, null);
            Add_Action (Table.States (61), 33, 42);
            Add_Action (Table.States (61), 35, 43);
            Add_Error (Table.States (61));
            Add_Goto (Table.States (61), 47, 46);
            Add_Goto (Table.States (61), 48, 76);
            Add_Goto (Table.States (61), 50, 49);
            Add_Goto (Table.States (61), 51, 50);
            Add_Goto (Table.States (61), 52, 51);
            Add_Goto (Table.States (61), 53, 52);
            Add_Action (Table.States (62), 12, 81);
            Add_Action (Table.States (62), 26, 82);
            Add_Error (Table.States (62));
            Add_Action (Table.States (63), 12, 81);
            Add_Action (Table.States (63), 27, 83);
            Add_Error (Table.States (63));
            Add_Action (Table.States (64), 12, 81);
            Add_Action (Table.States (64), 28, 84);
            Add_Error (Table.States (64));
            Add_Action (Table.States (65), 16, 85);
            Add_Error (Table.States (65));
            Add_Action (Table.States (66), 18, 38);
            Add_Action (Table.States (66), 19, 39);
            Add_Action (Table.States (66), 20, 40);
            Add_Action (Table.States (66), 21, 41);
            Add_Action (Table.States (66), 33, 86);
            Add_Action (Table.States (66), 35, 43);
            Add_Error (Table.States (66));
            Add_Goto (Table.States (66), 47, 46);
            Add_Goto (Table.States (66), 50, 87);
            Add_Goto (Table.States (66), 51, 50);
            Add_Goto (Table.States (66), 52, 51);
            Add_Goto (Table.States (66), 53, 52);
            Add_Action (Table.States (67), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (53, 4), 2, null,
            null);
            Add_Action (Table.States (68), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (52, 2), 2, null,
            null);
            Add_Action (Table.States (69), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (53, 5), 2, null,
            null);
            Add_Action (Table.States (70), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (52, 3), 2,
            rhs_optional_item_3'Access, null);
            Add_Action (Table.States (71), 12, Reduce, (46, 0), 0, null, null);
            Add_Action (Table.States (71), 18, 38);
            Add_Action (Table.States (71), 19, 39);
            Add_Action (Table.States (71), 20, 40);
            Add_Action (Table.States (71), 21, 41);
            Add_Action (Table.States (71), 23, Reduce, (46, 0), 0, null, null);
            Add_Action (Table.States (71), 29, Reduce, (46, 0), 0, null, null);
            Add_Action (Table.States (71), 33, 42);
            Add_Conflict (Table.States (71), 33, (46, 0), 0, null, null);
            Add_Action (Table.States (71), 35, 43);
            Add_Action (Table.States (71), 36, Reduce, (46, 0), 0, null, null);
            Add_Error (Table.States (71));
            Add_Goto (Table.States (71), 46, 88);
            Add_Goto (Table.States (71), 47, 46);
            Add_Goto (Table.States (71), 48, 47);
            Add_Goto (Table.States (71), 49, 48);
            Add_Goto (Table.States (71), 50, 49);
            Add_Goto (Table.States (71), 51, 50);
            Add_Goto (Table.States (71), 52, 51);
            Add_Goto (Table.States (71), 53, 52);
            Add_Action (Table.States (72), 4, 89);
            Add_Action (Table.States (72), 5, 90);
            Add_Error (Table.States (72));
            Add_Action (Table.States (73), (23, 33, 36), (44, 0), 1, null, null);
            Add_Action (Table.States (74), (23, 33, 36), (43, 0), 4, nonterminal_0'Access, null);
            Add_Action (Table.States (75), 11, 91);
            Add_Action (Table.States (75), 12, Reduce, (46, 2), 2, null, null);
            Add_Action (Table.States (75), 23, Reduce, (46, 2), 2, null, null);
            Add_Action (Table.States (75), 29, Reduce, (46, 2), 2, null, null);
            Add_Action (Table.States (75), 33, Reduce, (46, 2), 2, null, null);
            Add_Action (Table.States (75), 36, Reduce, (46, 2), 2, null, null);
            Add_Error (Table.States (75));
            Add_Action (Table.States (76), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (49, 1), 2, null,
            null);
            Add_Action (Table.States (77), (23, 33, 36), (43, 1), 4, nonterminal_1'Access, null);
            Add_Action (Table.States (78), (23, 33, 36), (38, 4), 5, declaration_4'Access, null);
            Add_Action (Table.States (79), (1 =>  33), (39, 1), 4, null, null);
            Add_Action (Table.States (80), (1 =>  33), (39, 2), 4, null, null);
            Add_Action (Table.States (81), 18, 38);
            Add_Action (Table.States (81), 19, 39);
            Add_Action (Table.States (81), 20, 40);
            Add_Action (Table.States (81), 21, 41);
            Add_Action (Table.States (81), 33, 42);
            Add_Action (Table.States (81), 35, 43);
            Add_Error (Table.States (81));
            Add_Goto (Table.States (81), 47, 46);
            Add_Goto (Table.States (81), 48, 47);
            Add_Goto (Table.States (81), 49, 92);
            Add_Goto (Table.States (81), 50, 49);
            Add_Goto (Table.States (81), 51, 50);
            Add_Goto (Table.States (81), 52, 51);
            Add_Goto (Table.States (81), 53, 52);
            Add_Action (Table.States (82), 11, Reduce, (53, 0), 3, null, null);
            Add_Action (Table.States (82), 12, Reduce, (53, 0), 3, null, null);
            Add_Action (Table.States (82), 18, Reduce, (53, 0), 3, null, null);
            Add_Action (Table.States (82), 19, Reduce, (53, 0), 3, null, null);
            Add_Action (Table.States (82), 20, Reduce, (53, 0), 3, null, null);
            Add_Action (Table.States (82), 21, Reduce, (53, 0), 3, null, null);
            Add_Action (Table.States (82), 22, 93);
            Add_Action (Table.States (82), 23, Reduce, (53, 0), 3, null, null);
            Add_Action (Table.States (82), 26, Reduce, (53, 0), 3, null, null);
            Add_Action (Table.States (82), 27, Reduce, (53, 0), 3, null, null);
            Add_Action (Table.States (82), 28, Reduce, (53, 0), 3, null, null);
            Add_Action (Table.States (82), 29, Reduce, (53, 0), 3, null, null);
            Add_Action (Table.States (82), 33, Reduce, (53, 0), 3, null, null);
            Add_Action (Table.States (82), 35, Reduce, (53, 0), 3, null, null);
            Add_Action (Table.States (82), 36, Reduce, (53, 0), 3, null, null);
            Add_Error (Table.States (82));
            Add_Action (Table.States (83), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (52, 0), 3, null,
            null);
            Add_Action (Table.States (84), 11, Reduce, (51, 0), 3, null, null);
            Add_Action (Table.States (84), 12, Reduce, (51, 0), 3, null, null);
            Add_Action (Table.States (84), 18, Reduce, (51, 0), 3, null, null);
            Add_Action (Table.States (84), 19, Reduce, (51, 0), 3, null, null);
            Add_Action (Table.States (84), 20, Reduce, (51, 0), 3, null, null);
            Add_Action (Table.States (84), 21, Reduce, (51, 0), 3, null, null);
            Add_Action (Table.States (84), 23, Reduce, (51, 0), 3, null, null);
            Add_Action (Table.States (84), 24, 94);
            Add_Action (Table.States (84), 25, 95);
            Add_Action (Table.States (84), 26, Reduce, (51, 0), 3, null, null);
            Add_Action (Table.States (84), 27, Reduce, (51, 0), 3, null, null);
            Add_Action (Table.States (84), 28, Reduce, (51, 0), 3, null, null);
            Add_Action (Table.States (84), 29, Reduce, (51, 0), 3, null, null);
            Add_Action (Table.States (84), 31, 96);
            Add_Action (Table.States (84), 33, Reduce, (51, 0), 3, null, null);
            Add_Action (Table.States (84), 35, Reduce, (51, 0), 3, null, null);
            Add_Action (Table.States (84), 36, Reduce, (51, 0), 3, null, null);
            Add_Error (Table.States (84));
            Add_Action (Table.States (85), 33, 97);
            Add_Error (Table.States (85));
            Add_Action (Table.States (86), 11, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (86), 12, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (86), 18, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (86), 19, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (86), 20, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (86), 21, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (86), 23, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (86), 24, 67);
            Add_Action (Table.States (86), 25, 68);
            Add_Action (Table.States (86), 26, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (86), 27, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (86), 28, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (86), 29, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (86), 31, 69);
            Add_Action (Table.States (86), 33, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (86), 35, Reduce, (50, 0), 1, null, null);
            Add_Action (Table.States (86), 36, Reduce, (50, 0), 1, null, null);
            Add_Error (Table.States (86));
            Add_Action (Table.States (87), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (48, 1), 3, null,
            null);
            Add_Action (Table.States (88), (12, 23, 29, 33, 36), (45, 1), 3, null, null);
            Add_Action (Table.States (89), 5, 98);
            Add_Error (Table.States (89));
            Add_Action (Table.States (90), 33, 99);
            Add_Error (Table.States (90));
            Add_Action (Table.States (91), (12, 23, 29, 33, 36), (46, 3), 3, null, null);
            Add_Action (Table.States (92), 12, Reduce, (54, 1), 3, null, null);
            Add_Action (Table.States (92), 18, 38);
            Add_Action (Table.States (92), 19, 39);
            Add_Action (Table.States (92), 20, 40);
            Add_Action (Table.States (92), 21, 41);
            Add_Action (Table.States (92), 26, Reduce, (54, 1), 3, null, null);
            Add_Action (Table.States (92), 27, Reduce, (54, 1), 3, null, null);
            Add_Action (Table.States (92), 28, Reduce, (54, 1), 3, null, null);
            Add_Action (Table.States (92), 33, 42);
            Add_Action (Table.States (92), 35, 43);
            Add_Error (Table.States (92));
            Add_Goto (Table.States (92), 47, 46);
            Add_Goto (Table.States (92), 48, 76);
            Add_Goto (Table.States (92), 50, 49);
            Add_Goto (Table.States (92), 51, 50);
            Add_Goto (Table.States (92), 52, 51);
            Add_Goto (Table.States (92), 53, 52);
            Add_Action (Table.States (93), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (53, 1), 4, null,
            null);
            Add_Action (Table.States (94), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (53, 2), 4, null,
            null);
            Add_Action (Table.States (95), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (52, 1), 4, null,
            null);
            Add_Action (Table.States (96), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (53, 3), 4, null,
            null);
            Add_Action (Table.States (97), 17, 100);
            Add_Error (Table.States (97));
            Add_Action (Table.States (98), (12, 23, 29, 33, 36), (45, 3), 4, null, null);
            Add_Action (Table.States (99), 16, 101);
            Add_Error (Table.States (99));
            Add_Action (Table.States (100), (11, 12, 18, 19, 20, 21, 23, 26, 27, 28, 29, 33, 35, 36), (47, 0), 5, null,
            null);
            Add_Action (Table.States (101), 33, 102);
            Add_Error (Table.States (101));
            Add_Action (Table.States (102), (12, 23, 29, 33, 36), (45, 2), 6, null, null);
         end Subr_1;
      begin
         Subr_1;
      end;

      WisiToken.Parse.LR.Parser_No_Recover.New_Parser
        (Parser,
         Trace,
         Lexer.New_Lexer (Trace.Descriptor),
         Table,
         User_Data,
         Max_Parallel         => 15,
         Terminate_Same_State => True);
   end Create_Parser;
end Wisitoken_Grammar_Main;
