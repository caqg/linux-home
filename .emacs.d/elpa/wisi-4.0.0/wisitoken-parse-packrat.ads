--  Abstract :
--
--  Types and operations for a packrat parser runtime.
--
--  References:
--
--  [ford thesis] Bryan Ford thesis http://bford.info/pub/lang/thesis
--
--  [langkit]     AdaCore langkit   https://github.com/adacore/langkit
--
--  [tratt 2010]  http://tratt.net/laurie/research/pubs/papers/
--                tratt__direct_left_recursive_parsing_expression_grammars.pdf
--
--  [warth 2008]  Warth, A., Douglass, J.R. and Millstein, T.D., 2008. Packrat
--                parsers can support left recursion. PEPM, 8, pp.103-110.
--
--  Copyright (C) 2018, 2020 - 2021 Free Software Foundation, Inc.
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

--  Design:
--
--  [ford thesis] uses Haskell lazy evaluation, and does not use a
--  lexer. We use a lexer to reduce the memory requirement. Although
--  eliminating the lexer would make it easier to support additional
--  syntax for a preprocessor or template generator.
--
--  [langkit] uses a lexer, and implements lazy evaluation via
--  Memo_State, Memo_Entry as we do here, except that their result
--  type is a specific AST type provided by a generic parameter; we
--  use the general purpose Syntax_Tree.Tree type.
--
--  [langkit] also applies a memory optimization; it only saves the
--  last 16 results for each nonterminal. We don't do that yet, so we
--  can get some data on how well that works.

pragma License (Modified_GPL);
with WisiToken.Syntax_Trees;
package WisiToken.Parse.Packrat is

   type Parser is abstract new Base_Parser with null record;

   overriding
   procedure Execute_Actions
     (Parser              : in out Packrat.Parser;
      Action_Region_Bytes : in     WisiToken.Buffer_Region := WisiToken.Null_Buffer_Region);

   function Image_Pos
     (Tree    : in Syntax_Trees.Tree;
      Stream  : in Syntax_Trees.Stream_ID;
      Element : in Syntax_Trees.Stream_Index)
     return String
   with Pre => Tree.Contains (Stream, Element);
   --  "0" for Invalid_Stream_Index, Node_Index'Image otherwise.

end WisiToken.Parse.Packrat;
