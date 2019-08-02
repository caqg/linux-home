--  Abstract:
--
--  A generic queue, allowing definite non-limited item types.
--
--  Copyright (C) 2004, 2008, 2009, 2011, 2017, 2019 Free Software Foundation All Rights Reserved.
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

generic
   type Item_Type is private;
package SAL.Gen_Bounded_Definite_Queues is
   pragma Pure;

   type Queue_Type (Size : Positive) is tagged private;
   --  Size is maximum number of items in the queue.
   --  Tagged to allow Object.Method syntax.

   function Get_Overflow_Handling (Queue : in Queue_Type) return Overflow_Action_Type;
   procedure Set_Overflow_Handling (Queue : in out Queue_Type; Handling : in Overflow_Action_Type);
   --  See Add for meaning of Overflow_Handling. Default is Error.

   procedure Clear (Queue : in out Queue_Type);
   --  Empty Queue of all items.

   function Count (Queue : in Queue_Type) return Natural;
   --  Returns count of items in the Queue

   function Is_Empty (Queue : in Queue_Type) return Boolean;
   --  Returns true if no items are in Queue.

   function Is_Full (Queue : in Queue_Type) return Boolean;
   --  Returns true if Queue is full.

   function Remove (Queue : in out Queue_Type) return Item_Type;
   --  Remove head item from Queue, return it.
   --
   --  Raises Container_Empty if Is_Empty.

   function Get (Queue : in out Queue_Type) return Item_Type renames Remove;

   procedure Drop (Queue : in out Queue_Type);
   --  Remove head item from Queue, discard it.
   --
   --  Raises Container_Empty if Is_Empty.

   function Peek (Queue : in Queue_Type; N : Integer := 0) return Item_Type;
   --  Return a copy of a queue item, without removing it. N = 0 is
   --  the queue head.

   procedure Add (Queue : in out Queue_Type; Item : in Item_Type);
   --  Add Item to the tail of Queue.
   --
   --  If Queue is full, result depends on Queue.Overflow_Handling:
   --
   --  when Overwrite, an implicit Remove is done (and the data
   --  discarded), then Add is done.
   --
   --  when Error, raises Container_Full.

   procedure Put (Queue : in out Queue_Type; Item : in Item_Type) renames Add;

   procedure Add_To_Head (Queue : in out Queue_Type; Item : in Item_Type);
   --  Add Item to the head of Queue.
   --
   --  If Queue is full, result depends on Queue.Overflow_Handling:
   --
   --  when Overwrite, an implicit Remove is done (and the data
   --  discarded), then Add is done.
   --
   --  when Error, raises Container_Full.

private

   type Item_Array_Type is array (Positive range <>) of Item_Type;

   type Queue_Type (Size : Positive) is tagged record
      Overflow_Handling : Overflow_Action_Type := Error;

      Head  : Natural := 0;
      Tail  : Natural := 0;
      Count : Natural := 0;
      Data  : Item_Array_Type (1 .. Size);
      --  Add at Tail + 1, remove at Head. Count is current count;
      --  easier to keep track of that than to compute Is_Empty for
      --  each Add and Remove.
   end record;

end SAL.Gen_Bounded_Definite_Queues;
