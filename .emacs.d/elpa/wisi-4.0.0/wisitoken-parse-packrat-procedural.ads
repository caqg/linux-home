--  Abstract :
--
--  Procedural packrat parser, supporting only direct left recursion.
--
--  Coding style, algorithm is the same as generated by
--  wisi-generate_packrat, but in procedural form.
--
--  References:
--
--  See parent.
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

with WisiToken.Productions;
package WisiToken.Parse.Packrat.Procedural is

   --  These types duplicate Packrat.Generated. We keep them separate so
   --  we can experiment with ways of implementing indirect left
   --  recursion.

   type Memo_State is (No_Result, Failure, Success);
   subtype Result_States is Memo_State range Failure .. Success;

   type Memo_Entry (State : Memo_State := No_Result) is record
      case State is
      when No_Result =>
         null;

      when Failure =>
         null;

      when Success =>
         Result   : Syntax_Trees.Node_Access;
         Last_Pos : Syntax_Trees.Stream_Index;

      end case;
   end record;

   subtype Positive_Node_Index is Syntax_Trees.Node_Index range 1 .. Syntax_Trees.Node_Index'Last;
   package Memos is new SAL.Gen_Unbounded_Definite_Vectors
     (Positive_Node_Index, Memo_Entry, Default_Element => (others => <>));
   --  Memos is indexed by Node_Index of terminals in Shared_Stream
   --  (incremental parse is not supported).

   type Derivs is array (Token_ID range <>) of Memos.Vector;

   type Parser (First_Nonterminal, Last_Nonterminal : Token_ID) is new Packrat.Parser
   with record
      Grammar               : WisiToken.Productions.Prod_Arrays.Vector;
      Start_ID              : Token_ID;
      Direct_Left_Recursive : Token_ID_Set (First_Nonterminal .. Last_Nonterminal);
      Derivs                : Procedural.Derivs (First_Nonterminal .. Last_Nonterminal);
   end record;

   function Create
     (Grammar               : in WisiToken.Productions.Prod_Arrays.Vector;
      Direct_Left_Recursive : in Token_ID_Set;
      Start_ID              : in Token_ID;
      Lexer                 : in WisiToken.Lexer.Handle;
      Productions           : in WisiToken.Syntax_Trees.Production_Info_Trees.Vector;
      User_Data             : in WisiToken.Syntax_Trees.User_Data_Access)
     return Procedural.Parser;

   overriding procedure Parse
     (Parser     : in out Procedural.Parser;
      Log_File   : in     Ada.Text_IO.File_Type;
      Edits      : in     KMN_Lists.List := KMN_Lists.Empty_List;
      Pre_Edited : in     Boolean        := False);
   --  Raises Parse_Error if Edits is not empty.

end WisiToken.Parse.Packrat.Procedural;