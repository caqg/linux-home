--  generated parser support file. -*- buffer-read-only:t  -*-
--  command line: wisitoken-bnf-generate.exe  --generate LALR Ada re2c PROCESS wisitoken_grammar.wy
--

--  Copyright (C) 2017 - 2022 Free Software Foundation, Inc.
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

with WisiToken.Syntax_Trees;
with WisiToken.Parse.LR.Parser_No_Recover;
package Wisitoken_Grammar_Main is

   function Create_Parser
     (Trace      : in WisiToken.Trace_Access;
      User_Data  : in WisiToken.Syntax_Trees.User_Data_Access)
     return WisiToken.Parse.LR.Parser_No_Recover.Parser;

end Wisitoken_Grammar_Main;
