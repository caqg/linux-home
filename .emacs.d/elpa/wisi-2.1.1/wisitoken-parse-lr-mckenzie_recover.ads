--  Abstract :
--
--  Implement [McKenzie] error recovery, extended to parallel parsers.
--
--  References:
--
--  [McKenzie] McKenzie, Bruce J., Yeatman, Corey, and De Vere,
--  Lorraine. Error repair in shift reduce parsers. ACM Trans. Prog.
--  Lang. Syst., 17(4):672-689, July 1995.  Described in [Grune 2008] ref 321.
--
--  [Grune 2008] Parsing Techniques, A Practical Guide, Second
--  Edition. Dick Grune, Ceriel J.H. Jacobs.
--
--  Copyright (C) 2017 - 2019 Free Software Foundation, Inc.
--
--  This library is free software;  you can redistribute it and/or modify it
--  under terms of the  GNU General Public License  as published by the Free
--  Software  Foundation;  either version 3,  or (at your  option) any later
--  version. This library is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN-
--  TABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
--  As a special exception under Section 7 of GPL version 3, you are granted
--  additional permissions described in the GCC Runtime Library Exception,
--  version 3.1, as published by the Free Software Foundation.

pragma License (Modified_GPL);

with Ada.Task_Attributes;
with WisiToken.Parse.LR.Parser;
with WisiToken.Lexer;
package WisiToken.Parse.LR.McKenzie_Recover is

   Bad_Config : exception;
   --  Raised when a config is determined to violate some programming
   --  convention; abandon it.

   type Recover_Status is (Fail_Check_Delta, Fail_Enqueue_Limit, Fail_No_Configs_Left, Fail_Programmer_Error, Success);

   function Recover (Shared_Parser : in out WisiToken.Parse.LR.Parser.Parser) return Recover_Status;
   --  Attempt to modify Parser.Parsers state and Parser.Lookahead to
   --  allow recovering from an error state.

   Force_Full_Explore        : Boolean := False;
   --  Sometimes recover throws an exception in a race condition case
   --  that is hard to reproduce. Setting this True ignores all Success,
   --  so all configs are checked.

   Force_High_Cost_Solutions : Boolean := False;
   --  Similarly, setting this true keeps all solutions that are found,
   --  and forces at least three.

private
   use all type WisiToken.Syntax_Trees.Node_Index;

   ----------
   --  Visible for language-specific child packages. Alphabetical.

   procedure Check (ID : Token_ID; Expected_ID : in Token_ID)
   with Inline => True;
   --  Check that ID = Expected_ID; raise Assertion_Error if not.
   --  Implemented using 'pragma Assert'.

   function Current_Token
     (Terminals                 : in     Base_Token_Arrays.Vector;
      Terminals_Current         : in out Base_Token_Index;
      Restore_Terminals_Current :    out WisiToken.Base_Token_Index;
      Insert_Delete             : in out Sorted_Insert_Delete_Arrays.Vector;
      Current_Insert_Delete     : in out SAL.Base_Peek_Type;
      Prev_Deleted              : in     Recover_Token_Index_Arrays.Vector)
     return Base_Token;
   --  Return the current token, from either Terminals or Insert_Delete;
   --  set up for Next_Token.
   --
   --  See Next_Token for more info.

   function Current_Token_ID_Peek
     (Terminals             : in     Base_Token_Arrays.Vector;
      Terminals_Current     : in     Base_Token_Index;
      Insert_Delete         : in     Sorted_Insert_Delete_Arrays.Vector;
      Current_Insert_Delete : in     SAL.Base_Peek_Type)
     return Token_ID;
   --  Return the current token from either Terminals or
   --  Insert_Delete, without setting up for Next_Token.

   procedure Current_Token_ID_Peek_3
     (Terminals             : in     Base_Token_Arrays.Vector;
      Terminals_Current     : in     Base_Token_Index;
      Insert_Delete         : in     Sorted_Insert_Delete_Arrays.Vector;
      Current_Insert_Delete : in     SAL.Base_Peek_Type;
      Prev_Deleted          : in     Recover_Token_Index_Arrays.Vector;
      Tokens                :    out Token_ID_Array_1_3);
   --  Return the current token (in Tokens (1)) from either Terminals or
   --  Insert_Delete, without setting up for Next_Token. Return the two
   --  following tokens in Tokens (2 .. 3).

   procedure Delete_Check
     (Terminals : in     Base_Token_Arrays.Vector;
      Config    : in out Configuration;
      ID        : in     Token_ID);
   --  Check that Terminals (Config.Current_Shared_Token) = ID. Append a
   --  Delete op to Config.Ops, and insert it in Config.Insert_Delete in
   --  token_index order.
   --
   --  This or the next routine must be used instead of Config.Ops.Append
   --  (Delete...) unless the code also takes care of changing
   --  Config.Current_Shared_Token. Note that this routine does _not_
   --  increment Config.Current_Shared_Token, so it can only be used to
   --  delete one token.

   procedure Delete_Check
     (Terminals : in     Base_Token_Arrays.Vector;
      Config    : in out Configuration;
      Index     : in out     WisiToken.Token_Index;
      ID        : in     Token_ID);
   --  Check that Terminals (Index) = ID. Append a Delete op to
   --  Config.Ops, and insert it in Config.Insert_Delete in token_index
   --  order. Increments Index, for convenience when deleting several
   --  tokens.

   procedure Find_ID
     (Config         : in     Configuration;
      ID             : in     Token_ID;
      Matching_Index : in out SAL.Peek_Type);
   --  Search Config.Stack for a token with ID, starting at
   --  Matching_Index. If found, Matching_Index points to it.
   --  If not found, Matching_Index = Config.Stack.Depth.

   procedure Find_ID
     (Config         : in     Configuration;
      IDs            : in     Token_ID_Set;
      Matching_Index : in out SAL.Peek_Type);
   --  Search Config.Stack for a token with ID in IDs, starting at
   --  Matching_Index. If found, Matching_Index points to it.
   --  If not found, Matching_Index = Config.Stack.Depth.

   procedure Find_Descendant_ID
     (Tree           : in     Syntax_Trees.Tree;
      Config         : in     Configuration;
      ID             : in     Token_ID;
      ID_Set         : in     Token_ID_Set;
      Matching_Index : in out SAL.Peek_Type);
   --  Search Config.Stack for a token with id in ID_Set, with a
   --  descendant with id = ID, starting at Matching_Index. If found,
   --  Matching_Index points to it. If not found, Matching_Index =
   --  Config.Stack.Depth.

   procedure Find_Matching_Name
     (Config              : in     Configuration;
      Lexer               : access constant WisiToken.Lexer.Instance'Class;
      Name                : in     String;
      Matching_Name_Index : in out SAL.Peek_Type;
      Case_Insensitive    : in     Boolean);
   --  Search Config.Stack for a token matching Name, starting at
   --  Matching_Name_Index. If found, Matching_Name_Index points to it.
   --  If not found, Matching_Name_Index = Config.Stack.Depth.

   procedure Find_Matching_Name
     (Config              : in     Configuration;
      Lexer               : access constant WisiToken.Lexer.Instance'Class;
      Name                : in     String;
      Matching_Name_Index : in out SAL.Peek_Type;
      Other_ID            : in     Token_ID;
      Other_Count         :    out Integer;
      Case_Insensitive    : in     Boolean);
   --  Search Config.Stack for a token matching Name, starting at
   --  Matching_Name_Index. If found, Matching_Name_Index points to it.
   --  If not found, Matching_Name_Index = Config.Stack.Depth.
   --
   --  Also count tokens with ID = Other_ID.

   procedure Insert (Config : in out Configuration; ID : in Token_ID);
   --  Append an Insert op to Config.Ops, and insert it in
   --  Config.Insert_Deleted in token_index order.

   procedure Insert (Config : in out Configuration; IDs : in Token_ID_Array);
   --  Call Insert for each item in IDs.

   function Next_Token
     (Terminals                 : in     Base_Token_Arrays.Vector;
      Terminals_Current         : in out Base_Token_Index;
      Restore_Terminals_Current : in out WisiToken.Base_Token_Index;
      Insert_Delete             : in out Sorted_Insert_Delete_Arrays.Vector;
      Current_Insert_Delete     : in out SAL.Base_Peek_Type;
      Prev_Deleted              : in     Recover_Token_Index_Arrays.Vector)
     return Base_Token;
   --  Return the next token, from either Terminals or Insert_Delete;
   --  update Terminals_Current or Current_Insert_Delete.
   --
   --  If result is Insert_Delete.Last_Index, Current_Insert_Delete =
   --  Last_Index; Insert_Delete is cleared and Current_Insert_Delete
   --  reset on next call.
   --
   --  When done parsing, caller must reset actual Terminals_Current to
   --  Restore_Terminals_Current.
   --
   --  Insert_Delete contains only Insert and Delete ops, in token_index
   --  order. Those ops are applied when Terminals_Current =
   --  op.token_index.
   --
   --  Prev_Deleted contains tokens deleted in previous recover
   --  operations; those are skipped.

   procedure Push_Back (Config : in out Configuration);
   --  Pop the top Config.Stack item, set Config.Current_Shared_Token to
   --  the first terminal in that item. If the item is empty,
   --  Config.Current_Shared_Token is unchanged.
   --
   --  If any earlier Insert or Delete items in Config.Ops are for a
   --  token_index after that first terminal, they are added to
   --  Config.Insert_Delete in token_index order.

   procedure Push_Back_Check (Config : in out Configuration; Expected_ID : in Token_ID);
   --  In effect, call Check and Push_Back.

   procedure Push_Back_Check (Config : in out Configuration; Expected : in Token_ID_Array);
   --  Call Push_Back_Check for each item in Expected.

   procedure Put
     (Message      : in     String;
      Trace        : in out WisiToken.Trace'Class;
      Parser_Label : in     Natural;
      Terminals    : in     Base_Token_Arrays.Vector;
      Config       : in     Configuration;
      Task_ID      : in     Boolean := True;
      Strategy     : in     Boolean := False);
   --  Put Message and an image of Config to Trace.

   procedure Put_Line
     (Trace        : in out WisiToken.Trace'Class;
      Parser_Label : in     Natural;
      Message      : in     String;
      Task_ID      : in     Boolean := True);
   --  Put message to Trace, with parser and task info.

   function Undo_Reduce_Valid
     (Stack : in out Recover_Stacks.Stack;
      Tree  : in     Syntax_Trees.Tree)
     return Boolean
     is ((Stack.Peek.Tree_Index /= WisiToken.Syntax_Trees.Invalid_Node_Index and then
            Tree.Is_Nonterm (Stack.Peek.Tree_Index)) or
           (Stack.Peek.Tree_Index = WisiToken.Syntax_Trees.Invalid_Node_Index and
              (not Stack.Peek.Token.Virtual and
                 Stack.Peek.Token.Byte_Region = Null_Buffer_Region)));
   --  Undo_Reduce needs to know what tokens the nonterm contains, to
   --  push them on the stack. Thus we need either a valid Tree index, or
   --  an empty nonterm. If Token.Virtual, we can't trust
   --  Token.Byte_Region to determine empty.

   function Undo_Reduce
     (Stack : in out Recover_Stacks.Stack;
      Tree  : in     Syntax_Trees.Tree)
     return Ada.Containers.Count_Type
   with Pre => Undo_Reduce_Valid (Stack, Tree);
   --  Undo the reduction that produced the top stack item, return the
   --  token count for that reduction.

   procedure Undo_Reduce_Check
     (Config   : in out Configuration;
      Tree     : in     Syntax_Trees.Tree;
      Expected : in     Token_ID)
   with Inline => True;
   --  Call Check, Undo_Reduce.

   procedure Undo_Reduce_Check
     (Config   : in out Configuration;
      Tree     : in     Syntax_Trees.Tree;
      Expected : in     Token_ID_Array);
   --  Call Undo_Reduce_Check for each item in Expected.

   package Task_Attributes is new Ada.Task_Attributes (Integer, 0);

end WisiToken.Parse.LR.McKenzie_Recover;
