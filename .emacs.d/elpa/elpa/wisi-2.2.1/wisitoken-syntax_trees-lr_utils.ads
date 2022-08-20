--  Abstract :
--
--  Utilities for navigating syntax trees produced by an LR parser.
--
--  Copyright (C) 2019 Stephen Leake All Rights Reserved.
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

with Ada.Iterator_Interfaces;
package WisiToken.Syntax_Trees.LR_Utils is

   procedure Raise_Programmer_Error
     (Label      : in String;
      Descriptor : in WisiToken.Descriptor;
      Lexer      : in WisiToken.Lexer.Handle;
      Tree       : in WisiToken.Syntax_Trees.Tree;
      Terminals  : in WisiToken.Base_Token_Arrays.Vector;
      Node       : in WisiToken.Syntax_Trees.Node_Index);
   pragma No_Return (Raise_Programmer_Error);

   ----------
   --  List functions
   --
   --  A list has one of the following grammar forms:
   --
   --  list : list element | element ;
   --  list : element | list element ;
   --
   --  list : list separator element | element ;
   --  list : element | list separator element ;

   type Cursor is private;
   function Has_Element (Cursor : in LR_Utils.Cursor) return Boolean;

   function Node (Cursor : in LR_Utils.Cursor) return Node_Index;

   package Iterator_Interfaces is new Ada.Iterator_Interfaces (Cursor, Has_Element);

   type Iterator is new Iterator_Interfaces.Reversible_Iterator with private;

   overriding function First (Iter : Iterator) return Cursor;
   overriding function Last  (Iter : Iterator) return Cursor;

   overriding function Next (Iter : Iterator; Position : Cursor) return Cursor;

   overriding function Previous (Iter : Iterator; Position : Cursor) return Cursor;

   function Iterate
     (Tree         : in WisiToken.Syntax_Trees.Tree;
      Terminals    : in WisiToken.Base_Token_Array_Access;
      Lexer        : in WisiToken.Lexer.Handle;
      Descriptor   : in WisiToken.Descriptor_Access_Constant;
      Root         : in Valid_Node_Index;
      Element_ID   : in WisiToken.Token_ID;
      Separator_ID : in WisiToken.Token_ID := WisiToken.Invalid_Token_ID)
     return Iterator_Interfaces.Reversible_Iterator'Class;

   function Count (Iter : Iterator) return Ada.Containers.Count_Type;

private

   type Cursor is record
      Node : Node_Index;
   end record;

   type Iterator is new Iterator_Interfaces.Reversible_Iterator with record
      Tree         : WisiToken.Syntax_Trees.Tree;
      Terminals    : WisiToken.Base_Token_Array_Access;
      Lexer        : WisiToken.Lexer.Handle;
      Descriptor   : WisiToken.Descriptor_Access_Constant;
      Root         : Valid_Node_Index;
      List_ID      : WisiToken.Token_ID;
      Element_ID   : WisiToken.Token_ID;
      Separator_ID : WisiToken.Token_ID;
   end record;

end WisiToken.Syntax_Trees.LR_Utils;
