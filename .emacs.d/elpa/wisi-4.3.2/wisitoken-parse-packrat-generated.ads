--  Abstract :
--
--  Types and operations for a packrat parser runtime, with nonterm
--  parsing subprograms generated by wisi-generate.
--
--  References:
--
--  see parent.
--
--  Copyright (C) 2018 - 2022 Free Software Foundation, Inc.
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
with WisiToken.Syntax_Trees;
package WisiToken.Parse.Packrat.Generated is

   Recursive : exception;

   type Parser;

   type Parse_WisiToken_Accept is access
     function (Parser : in out Packrat.Generated.Parser; Last_Pos : in Syntax_Trees.Stream_Index) return Result_Type;

   type Parser (First_Nonterminal, Last_Nonterminal : Token_ID) is new WisiToken.Parse.Packrat.Parser
     (First_Nonterminal => First_Nonterminal,
      Last_Nonterminal  => Last_Nonterminal)
   with record
      Parse_WisiToken_Accept : Generated.Parse_WisiToken_Accept;
   end record;

   overriding procedure Parse
     (Parser     : in out Generated.Parser;
      Log_File   : in     Ada.Text_IO.File_Type;
      Edits      : in     KMN_Lists.List := KMN_Lists.Empty_List;
      Pre_Edited : in     Boolean        := False);
   --  Raises Parse_Error if Edits is not empty. Log_File, Pre_Edited are ignored.

end WisiToken.Parse.Packrat.Generated;