--  Abstract :
--
--  Syntax tree type and operations.
--
--  Rationale :
--
--  We provide Base_Tree and Tree in one package, because only Tree
--  needs an API; the only way Base_Tree is accessed is via Tree.
--
--  Copyright (C) 2018 - 2019 Free Software Foundation, Inc.

--  There is one syntax tree for each parser. There is one shared
--  Terminals array, matching the actual input text.
--
--  Copyright (C) 2018 Free Software Foundation, Inc.
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

with Ada.Finalization;
with SAL.Gen_Unbounded_Definite_Vectors;
with WisiToken.Lexer;
package WisiToken.Syntax_Trees is

   type Base_Tree is new Ada.Finalization.Controlled with private;

   type Base_Tree_Access is access all Base_Tree;

   overriding procedure Finalize (Tree : in out Base_Tree);
   --  Free any allocated storage.

   type Tree is new Ada.Finalization.Controlled with private;

   procedure Initialize
     (Branched_Tree : in out Tree;
      Shared_Tree   : in     Base_Tree_Access;
      Flush         : in     Boolean);
   --  Set Branched_Tree to refer to Shared_Tree.

   overriding procedure Finalize (Tree : in out Syntax_Trees.Tree);
   --  Free any allocated storage.

   type Node_Index is range 0 .. Integer'Last;
   subtype Valid_Node_Index is Node_Index range 1 .. Node_Index'Last;

   Invalid_Node_Index : constant Node_Index := Node_Index'First;

   type Valid_Node_Index_Array is array (Positive_Index_Type range <>) of Valid_Node_Index;
   --  Index matches Base_Token_Array, Augmented_Token_Array

   package Valid_Node_Index_Arrays is new SAL.Gen_Unbounded_Definite_Vectors
     (Positive_Index_Type, Valid_Node_Index, Default_Element => Valid_Node_Index'First);
   --  Index matches Valid_Node_Index_Array.

   type Node_Label is
     (Shared_Terminal,    -- text is user input, accessed via Parser.Terminals
      Virtual_Terminal,   -- no text; inserted during error recovery
      Virtual_Identifier, -- text in user data, created during tree rewrite
      Nonterm             -- contains terminals/nonterminals/identifiers
     );

   type User_Data_Type is tagged limited null record;
   --  Many test languages don't need this, so we default the procedures
   --  to null.

   type User_Data_Access is access all User_Data_Type'Class;

   procedure Set_Lexer_Terminals
     (User_Data : in out User_Data_Type;
      Lexer     : in     WisiToken.Lexer.Handle;
      Terminals : in     Base_Token_Array_Access)
   is null;

   procedure Reset (User_Data : in out User_Data_Type) is null;
   --  Reset to start a new parse.

   procedure Initialize_Actions
     (User_Data : in out User_Data_Type;
      Tree      : in     Syntax_Trees.Tree'Class)
     is null;
   --  Called by Execute_Actions, before processing the tree.

   procedure Lexer_To_Augmented
     (User_Data : in out          User_Data_Type;
      Token     : in              Base_Token;
      Lexer     : not null access WisiToken.Lexer.Instance'Class)
     is null;
   --  Read auxiliary data from Lexer, do something useful with it.
   --  Called before parsing, once for each token in the input stream.

   procedure Delete_Token
     (User_Data   : in out User_Data_Type;
      Token_Index : in     WisiToken.Token_Index)
   is null;
   --  Token at Token_Index was deleted in error recovery; update
   --  remaining tokens and Tree as needed. Called from Execute_Actions
   --  for each deleted token, before processing the syntax tree.

   procedure Reduce
     (User_Data : in out User_Data_Type;
      Tree      : in out Syntax_Trees.Tree'Class;
      Nonterm   : in     Valid_Node_Index;
      Tokens    : in     Valid_Node_Index_Array)
   is null;
   --  Reduce Tokens to Nonterm. Nonterm.Byte_Region is computed by
   --  caller.

   type Semantic_Action is access procedure
     (User_Data : in out User_Data_Type'Class;
      Tree      : in out Syntax_Trees.Tree;
      Nonterm   : in     Valid_Node_Index;
      Tokens    : in     Valid_Node_Index_Array);
   --  Routines of this type are called by
   --  WisiToken.LR.Parser.Execute_Actions when it processes a Nonterm
   --  node in the syntax tree. Tokens are the children of Nonterm.

   Null_Action : constant Semantic_Action := null;

   procedure Clear (Tree : in out Syntax_Trees.Base_Tree);
   procedure Clear (Tree : in out Syntax_Trees.Tree);
   --  Delete all Elements and free associated memory; keep results of
   --  Initialize.

   procedure Flush (Tree : in out Syntax_Trees.Tree);
   --  Move all nodes in branched part to shared tree, set Flush mode
   --  True.

   procedure Set_Flush_False (Tree : in out Syntax_Trees.Tree);
   --  Set Flush mode False; use Flush to set True.

   function Flushed (Tree : in Syntax_Trees.Tree) return Boolean;

   function Copy_Subtree
     (Tree : in out Syntax_Trees.Tree;
      Root : in     Valid_Node_Index;
      Last : in     Valid_Node_Index)
     return Valid_Node_Index
   with Pre => Tree.Flushed;
   --  Deep copy (into Tree) subtree of Tree rooted at Root. Stop copying
   --  after children of Last are copied. Return root of new subtree.
   --
   --  Node index order is preserved. References to objects external to
   --  tree are shallow copied.

   function Add_Nonterm
     (Tree            : in out Syntax_Trees.Tree;
      Production      : in     Production_ID;
      Children        : in     Valid_Node_Index_Array;
      Action          : in     Semantic_Action := null;
      Default_Virtual : in     Boolean         := False)
     return Valid_Node_Index
   with Pre  => not Tree.Traversing;
   --  Add a new Nonterm node, which can be empty. Result points to the
   --  added node. If Children'Length = 0, set Nonterm.Virtual :=
   --  Default_Virtual.

   function Add_Terminal
     (Tree      : in out Syntax_Trees.Tree;
      Terminal  : in     Token_Index;
      Terminals : in     Base_Token_Arrays.Vector)
     return Valid_Node_Index
   with Pre => not Tree.Traversing;
   --  Add a new Terminal node. Terminal must be an index into Terminals.
   --  Result points to the added node.

   function Add_Terminal
     (Tree     : in out Syntax_Trees.Tree;
      Terminal : in     Token_ID)
     return Valid_Node_Index
   with Pre => not Tree.Traversing;
   --  Add a new Virtual_Terminal node with no parent. Result points to
   --  the added node.

   function Add_Identifier
     (Tree        : in out Syntax_Trees.Tree;
      ID          : in     Token_ID;
      Identifier  : in     Identifier_Index;
      Byte_Region : in     WisiToken.Buffer_Region)
     return Valid_Node_Index
   with Pre => Tree.Flushed and (not Tree.Traversing);
   --  Add a new Virtual_Identifier node with no parent. Byte_Region
   --  should point to an area in the source buffer related to the new
   --  identifier, to aid debugging. Result points to the added node.

   procedure Add_Child
     (Tree   : in out Syntax_Trees.Tree;
      Parent : in     Valid_Node_Index;
      Child  : in     Valid_Node_Index)
   with
     Pre => Tree.Flushed and
            (not Tree.Traversing) and
            Tree.Is_Nonterm (Parent);
   --  Child.Parent must already be set.

   procedure Set_Children
     (Tree     : in out Syntax_Trees.Tree;
      Node     : in     Valid_Node_Index;
      New_ID : in WisiToken.Production_ID;
      Children : in     Valid_Node_Index_Array)
   with
     Pre => Tree.Flushed and
            (not Tree.Traversing) and
            Tree.Is_Nonterm (Node);
   --  Set ID of Node to New_ID, and children to Children; set parent of
   --  Children to Node. Remove any Action.
   --
   --  New_ID is required, and Action removed, because this is most
   --  likely a different production.

   procedure Set_Node_Identifier
     (Tree       : in Syntax_Trees.Tree;
      Node       : in Valid_Node_Index;
      ID         : in Token_ID;
      Identifier : in Identifier_Index)
   with Pre => Tree.Flushed and
               Tree.Is_Nonterm (Node);
   --  Change Node to a Virtual_Identifier.

   procedure Set_State
     (Tree  : in out Syntax_Trees.Tree;
      Node  : in     Valid_Node_Index;
      State : in     State_Index);

   function State (Tree : in Syntax_Trees.Tree; Node : in Valid_Node_Index) return Unknown_State_Index;

   function Label (Tree : in Syntax_Trees.Tree; Node : in Valid_Node_Index) return Node_Label;

   function Children (Tree : in Syntax_Trees.Tree; Node : in Valid_Node_Index) return Valid_Node_Index_Array
   with Pre => Tree.Is_Nonterm (Node);

   function Child
     (Tree        : in Syntax_Trees.Tree;
      Node        : in Valid_Node_Index;
      Child_Index : in Positive_Index_Type)
     return Node_Index
   with Pre => Tree.Is_Nonterm (Node);

   function Has_Branched_Nodes (Tree : in Syntax_Trees.Tree) return Boolean;
   function Has_Children (Tree : in Syntax_Trees.Tree; Node : in Valid_Node_Index) return Boolean;
   function Has_Parent (Tree : in Syntax_Trees.Tree; Child : in Valid_Node_Index) return Boolean;
   function Has_Parent (Tree : in Syntax_Trees.Tree; Children : in Valid_Node_Index_Array) return Boolean;
   function Is_Empty (Tree : in Syntax_Trees.Tree; Node : in Valid_Node_Index) return Boolean;
   function Is_Nonterm (Tree : in Syntax_Trees.Tree; Node : in Valid_Node_Index) return Boolean;
   function Is_Terminal (Tree : in Syntax_Trees.Tree; Node : in Valid_Node_Index) return Boolean;
   function Is_Virtual (Tree : in Syntax_Trees.Tree; Node : in Valid_Node_Index) return Boolean;
   function Is_Virtual_Identifier (Tree : in Syntax_Trees.Tree; Node : in Valid_Node_Index) return Boolean;
   function Traversing (Tree : in Syntax_Trees.Tree) return Boolean;

   function Parent
     (Tree  : in Syntax_Trees.Tree;
      Node  : in Valid_Node_Index;
      Count : in Positive := 1)
     return Node_Index;
   --  Return Count parent of Node.

   procedure Set_Name_Region
     (Tree   : in out Syntax_Trees.Tree;
      Node   : in     Valid_Node_Index;
      Region : in     Buffer_Region)
   with Pre => Tree.Is_Nonterm (Node);

   function ID
     (Tree : in Syntax_Trees.Tree;
      Node : in Valid_Node_Index)
     return WisiToken.Token_ID;

   function Production_ID
     (Tree : in Syntax_Trees.Tree;
      Node : in Valid_Node_Index)
     return WisiToken.Production_ID
   with Pre => Tree.Is_Nonterm (Node);

   function Byte_Region
     (Tree : in Syntax_Trees.Tree;
      Node : in Valid_Node_Index)
     return WisiToken.Buffer_Region;

   function RHS_Index
     (Tree : in Syntax_Trees.Tree;
      Node : in Valid_Node_Index)
     return Natural
   with Pre => Tree.Is_Nonterm (Node);

   function Same_Token
     (Tree_1  : in Syntax_Trees.Tree'Class;
      Index_1 : in Valid_Node_Index;
      Tree_2  : in Syntax_Trees.Tree'Class;
      Index_2 : in Valid_Node_Index)
     return Boolean;
   --  True if the two tokens have the same ID and Byte_Region.

   function Recover_Token
     (Tree : in Syntax_Trees.Tree;
      Node : in Valid_Node_Index)
     return WisiToken.Recover_Token;

   function Recover_Token_Array
     (Tree  : in Syntax_Trees.Tree;
      Nodes : in Valid_Node_Index_Array)
     return WisiToken.Recover_Token_Array;
   --  For non-virtual terminals, copied from Tree.Terminals. For others,
   --  constructed from Tree data.

   procedure Set_Augmented
     (Tree  : in out Syntax_Trees.Tree;
      Node  : in     Valid_Node_Index;
      Value : in     Base_Token_Class_Access)
   with Pre => Tree.Is_Nonterm (Node);
   --  Value will be deallocated when Tree is finalized.

   function Augmented
     (Tree : in Syntax_Trees.Tree;
      Node : in Valid_Node_Index)
     return Base_Token_Class_Access
   with Pre => Tree.Is_Nonterm (Node);
   --  Returns result of Set_Augmented.

   function Action
     (Tree : in Syntax_Trees.Tree;
      Node : in Valid_Node_Index)
     return Semantic_Action
   with Pre => Tree.Is_Nonterm (Node);

   function Find_Ancestor
     (Tree : in Syntax_Trees.Tree;
      Node : in Valid_Node_Index;
      ID   : in Token_ID)
     return Node_Index;
   function Find_Ancestor
     (Tree : in Syntax_Trees.Tree;
      Node : in Valid_Node_Index;
      IDs  : in Token_ID_Array)
     return Node_Index;
   --  Return the ancestor of Node that contains ID, or Invalid_Node_Index if
   --  none match.

   function Find_Sibling
     (Tree : in Syntax_Trees.Tree;
      Node : in Valid_Node_Index;
      ID   : in Token_ID)
     return Node_Index
   with Pre => Tree.Has_Parent (Node);
   --  Return the sibling of Node that contains ID, or Invalid_Node_Index if
   --  none match.

   function Find_Child
     (Tree : in Syntax_Trees.Tree;
      Node : in Valid_Node_Index;
      ID   : in Token_ID)
     return Node_Index
   with Pre => Tree.Is_Nonterm (Node);
   --  Return the child of Node whose ID is ID, or Invalid_Node_Index if
   --  none match.

   function Find_Descendant
     (Tree : in Syntax_Trees.Tree;
      Node : in Valid_Node_Index;
      ID   : in Token_ID)
     return Node_Index;
   --  Return the descendant of Node (may be Node) whose ID is ID, or
   --  Invalid_Node_Index if none match.

   function Find_Min_Terminal_Index
     (Tree  : in Syntax_Trees.Tree;
      Index : in Token_Index)
     return Node_Index
   with Post => Find_Min_Terminal_Index'Result = Invalid_Node_Index or else
                Tree.Is_Nonterm (Find_Min_Terminal_Index'Result);
   --  Return the first node whose Min_Terminal_Index is Index, or
   --  Invalid_Node_Index if none match.

   function Find_Max_Terminal_Index
     (Tree  : in Syntax_Trees.Tree;
      Index : in Token_Index)
     return Node_Index
   with Post => Find_Max_Terminal_Index'Result = Invalid_Node_Index or else
                Tree.Is_Nonterm (Find_Max_Terminal_Index'Result);
   --  Return the first node whose Max_Terminal_Index is Index, or
   --  Invalid_Node_Index if none match.

   procedure Set_Root (Tree : in out Syntax_Trees.Tree; Root : in Valid_Node_Index);

   function Root (Tree : in Syntax_Trees.Tree) return Node_Index;
   --  Return value set by Set_Root; defaults to the last node added.
   --  returns Invalid_Node_Index if Tree is empty.

   procedure Process_Tree
     (Tree         : in out Syntax_Trees.Tree;
      Process_Node : access procedure
        (Tree : in out Syntax_Trees.Tree;
         Node : in     Valid_Node_Index);
      Root         : in     Node_Index := Invalid_Node_Index);
   --  Traverse subtree of Tree rooted at Root (default Tree.Root) in
   --  depth-first order, calling Process_Node on each node.

   function Identifier (Tree : in Syntax_Trees.Tree; Node : in Valid_Node_Index) return Base_Identifier_Index
   with Pre => Tree.Is_Virtual_Identifier (Node);

   function Terminal (Tree : in Syntax_Trees.Tree; Node : in Valid_Node_Index) return Base_Token_Index
   with Pre => Tree.Is_Terminal (Node);

   function Min_Terminal_Index (Tree : in Syntax_Trees.Tree; Node : in Valid_Node_Index) return Base_Token_Index;
   function Max_Terminal_Index (Tree : in Syntax_Trees.Tree; Node : in Valid_Node_Index) return Base_Token_Index;
   --  Returns lowest/highest index of shared terminal in subtree under
   --  Node. If result is Invalid_Token_Index, all terminals are virtual,
   --  or a nonterm is empty.

   function Get_Terminals (Tree : in Syntax_Trees.Tree; Node : in Valid_Node_Index) return Valid_Node_Index_Array;
   --  Return sequence of terminals in Node.
   --
   --  "Terminals" can be Shared_Terminal, Virtual_Terminal,
   --  Virtual_Identifier.

   function Get_Terminal_IDs (Tree : in Syntax_Trees.Tree; Node : in Valid_Node_Index) return Token_ID_Array;
   --  Same as Get_Terminals, but return the IDs.

   function First_Terminal_ID (Tree : in Syntax_Trees.Tree; Node : in Valid_Node_Index) return Token_ID;
   --  First of Get_Terminal_IDs

   function Get_IDs
     (Tree : in Syntax_Trees.Tree;
      Node : in Valid_Node_Index;
      ID   : in Token_ID)
     return Valid_Node_Index_Array;
   --  Return all descendants of Node matching ID.

   function Image
     (Tree             : in Syntax_Trees.Tree;
      Node             : in Valid_Node_Index;
      Descriptor       : in WisiToken.Descriptor;
      Include_Children : in Boolean := False)
     return String;
   function Image
     (Tree       : in Syntax_Trees.Tree;
      Nodes      : in Valid_Node_Index_Array;
      Descriptor : in WisiToken.Descriptor)
     return String;
   --  For debug and error messages.

   function First_Index (Tree : in Syntax_Trees.Tree) return Node_Index;
   function Last_Index (Tree : in Syntax_Trees.Tree) return Node_Index;

   package Node_Sets is new SAL.Gen_Unbounded_Definite_Vectors (Valid_Node_Index, Boolean, Default_Element => False);

   function Image
     (Item     : in Node_Sets.Vector;
      Inverted : in Boolean := False)
     return String;
   --  Simple list of numbers, for debugging

   procedure Print_Tree
     (Tree       : in Syntax_Trees.Tree;
      Descriptor : in WisiToken.Descriptor;
      Root       : in Node_Index := Invalid_Node_Index)
   with Pre => Tree.Flushed;
   --  Print tree rooted at Root (default Tree.Root) to
   --  Text_IO.Current_Output, for debugging.

private

   type Node (Label : Node_Label := Virtual_Terminal) is
   --  Label has a default to allow changing the label during tree editing.
   record
      ID : WisiToken.Token_ID := Invalid_Token_ID;

      Byte_Region : Buffer_Region := Null_Buffer_Region;
      --  Computed by Set_Children, used in Semantic_Check actions and debug
      --  messages.

      Parent : Node_Index := Invalid_Node_Index;

      State : Unknown_State_Index := Unknown_State;
      --  Parse state that was on stack with this token, to allow undoing a
      --  reduce.

      case Label is
      when Shared_Terminal =>
         Terminal : Token_Index; -- into Parser.Terminals

      when Virtual_Terminal =>
         null;

      when Virtual_Identifier =>
         Identifier : Identifier_Index; -- into user data

      when Nonterm =>
         Virtual : Boolean := False;
         --  True if any child node is Virtual_Terminal or Nonterm with Virtual
         --  set. Used by Semantic_Check actions.

         RHS_Index : Natural;
         --  With ID, index into Productions.
         --  Used for debug output, keep for future use.

         Action : Semantic_Action := null;

         Name : Buffer_Region := Null_Buffer_Region;
         --  Name is set and checked by Semantic_Check actions.

         Children : Valid_Node_Index_Arrays.Vector;

         Min_Terminal_Index : Base_Token_Index := Invalid_Token_Index;
         --  Cached for push_back of nonterminals during recovery

         Max_Terminal_Index : Base_Token_Index := Invalid_Token_Index;
         --  Cached for building a WisiToken tree from a libadalang tree.

         Augmented : Base_Token_Class_Access := null;
      end case;
   end record;

   subtype Nonterm_Node is Node (Nonterm);

   package Node_Arrays is new SAL.Gen_Unbounded_Definite_Vectors
     (Valid_Node_Index, Node, Default_Element => (others => <>));

   type Base_Tree is new Ada.Finalization.Controlled with record
      Nodes : Node_Arrays.Vector;
      --  During normal parsing, tokens are added to Nodes by "parallel"
      --  LALR parsers, but they are all run from one Ada task, so there's
      --  no need for Nodes to be Protected. Packrat parsing also has a
      --  single Ada task.
      --
      --  During McKenzie_Recover, which has multiple Ada tasks, the syntax
      --  tree is read but not modified.

      Augmented_Present : Boolean := False;
      --  True if Set_Augmented has been called on any node. Declared in
      --  Base_Tree so it can be checked by Finalize (Base_Tree) and
      --  Finalize (Tree).

      Traversing : Boolean := False;
      --  True while traversing tree in Process_Tree.
      --  Declared in Base_Tree so it is cleared by Finalize.

   end record;

   type Tree is new Ada.Finalization.Controlled with record
      Shared_Tree : Base_Tree_Access;
      --  If we need to set anything (ie parent) in Shared_Tree, we move the
      --  branch point instead, unless Flush = True.

      Last_Shared_Node : Node_Index := Invalid_Node_Index;
      Branched_Nodes   : Node_Arrays.Vector;
      Flush            : Boolean    := False;
      --  If Flush is True, all nodes are in Shared_Tree. Otherwise, all
      --  greater than Last_Shared_Node are in Branched_Nodes.
      --
      --  We maintain Last_Shared_Node when Flush is True or False, so
      --  subprograms that have no reason to check Flush can rely on
      --  Last_Shared_Node.

      Root : Node_Index := Invalid_Node_Index;
   end record with
     Type_Invariant => (if Tree.Flush then not Tree.Has_Branched_Nodes);

end WisiToken.Syntax_Trees;
