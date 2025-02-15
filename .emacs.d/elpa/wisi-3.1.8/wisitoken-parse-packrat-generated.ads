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

   type Memo_State is (No_Result, Failure, Success);
   subtype Result_States is Memo_State range Failure .. Success;

   type Memo_Entry (State : Memo_State := No_Result) is record

      case State is
      when No_Result =>
         Recursive : Boolean := False;

      when Failure =>
         null;

      when Success =>
         Result : aliased Syntax_Trees.Node_Access;

         Last_Pos : Syntax_Trees.Stream_Index;
      end case;
   end record;

   subtype Positive_Node_Index is Syntax_Trees.Node_Index range 1 .. Syntax_Trees.Node_Index'Last;
   package Memos is new SAL.Gen_Unbounded_Definite_Vectors
     (Positive_Node_Index, Memo_Entry, Default_Element => (others => <>));
   --  Memos is indexed by Node_Index of terminals in Shared_Stream
   --  (incremental parse is not supported).

   subtype Result_Type is Memo_Entry
   with Dynamic_Predicate => Result_Type.State in Result_States;

   package Derivs is new SAL.Gen_Unbounded_Definite_Vectors
     (Token_ID, Memos.Vector, Default_Element => Memos.Empty_Vector);

   type Parse_WisiToken_Accept is access
     --  WORKAROUND: using Packrat.Parser'Class here hits a GNAT Bug box in GPL 2018.
     function (Parser : in out Base_Parser'Class; Last_Pos : in Syntax_Trees.Stream_Index) return Result_Type;

   type Parser is new Packrat.Parser with record
      Derivs : Generated.Derivs.Vector; --  FIXME packrat: use discriminated array, as in procedural

      Parse_WisiToken_Accept : Generated.Parse_WisiToken_Accept;
   end record;

   overriding procedure Parse
     (Parser     : in out Generated.Parser;
      Log_File   : in     Ada.Text_IO.File_Type;
      Edits      : in     KMN_Lists.List := KMN_Lists.Empty_List;
      Pre_Edited : in     Boolean        := False);
   --  Raises Parse_Error if Edits is not empty. Log_File, Pre_Edited are ignored.

end WisiToken.Parse.Packrat.Generated;
