--  Abstract:
--
--  See spec.
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

package body SAL.Gen_Bounded_Definite_Queues is

   --  Local subprograms

   function Wrap (Queue : in Queue_Type; I : in Integer) return Integer
   is begin
      if I > Queue.Size then
         return I - Queue.Size;
      elsif I < 1 then
         return Queue.Size + I;
      else
         return I;
      end if;
   end Wrap;

   ----------
   --  Public subprograms

   function Get_Overflow_Handling (Queue : in Queue_Type) return Overflow_Action_Type
   is begin
      return Queue.Overflow_Handling;
   end Get_Overflow_Handling;

   procedure Set_Overflow_Handling (Queue : in out Queue_Type; Handling : in Overflow_Action_Type)
   is begin
      Queue.Overflow_Handling := Handling;
   end Set_Overflow_Handling;

   procedure Clear (Queue : in out Queue_Type) is
   begin
      Queue.Count := 0;
   end Clear;

   function Count (Queue : in Queue_Type) return Natural is
   begin
      return Queue.Count;
   end Count;

   function Is_Empty (Queue : in Queue_Type) return Boolean is
   begin
      return Queue.Count = 0;
   end Is_Empty;

   function Is_Full (Queue : in Queue_Type) return Boolean is
   begin
      return Queue.Count = Queue.Size;
   end Is_Full;

   function Remove (Queue : in out Queue_Type) return Item_Type
   is begin
      if Queue.Count = 0 then
         raise Container_Empty;
      end if;

      return Item : constant Item_Type := Queue.Data (Queue.Head)
      do
         Queue.Count := Queue.Count - 1;

         if Queue.Count > 0 then
            Queue.Head := Wrap (Queue, Queue.Head + 1);
         end if;
      end return;
   end Remove;

   procedure Drop (Queue : in out Queue_Type)
   is begin
      if Queue.Count = 0 then
         raise Container_Empty;
      end if;

      Queue.Count := Queue.Count - 1;

      if Queue.Count > 0 then
         Queue.Head := Wrap (Queue, Queue.Head + 1);
      end if;
   end Drop;

   function Peek (Queue : in Queue_Type; N : Integer := 0) return Item_Type
   is begin
      if Queue.Count = 0 then
         raise Container_Empty;
      end if;

      return Queue.Data (Wrap (Queue, Queue.Head + N));
   end Peek;

   procedure Add (Queue : in out Queue_Type; Item : in Item_Type) is
   begin
      if Queue.Count = Queue.Size then
         case Queue.Overflow_Handling is
         when Error =>
            raise Container_Full;
         when Overwrite =>
            Queue.Count := Queue.Count - 1;
            Queue.Head  := Wrap (Queue, Queue.Head + 1);
         end case;
      end if;

      if Queue.Count = 0 then
         Queue.Tail     := 1;
         Queue.Head     := 1;
         Queue.Count    := 1;
         Queue.Data (1) := Item;
      else
         Queue.Tail              := Wrap (Queue, Queue.Tail + 1);
         Queue.Data (Queue.Tail) := Item;
         Queue.Count             := Queue.Count + 1;
      end if;
   end Add;

   procedure Add_To_Head (Queue : in out Queue_Type; Item : in Item_Type) is
   begin
      if Queue.Count = Queue.Size then
         case Queue.Overflow_Handling is
         when Error =>
            raise Container_Full;
         when Overwrite =>
            Queue.Count := Queue.Count - 1;
            Queue.Tail  := Wrap (Queue, Queue.Tail + 1);
         end case;
      end if;

      if Queue.Count = 0 then
         Queue.Tail     := 1;
         Queue.Head     := 1;
         Queue.Count    := 1;
         Queue.Data (1) := Item;
      else
         Queue.Head              := Wrap (Queue, Queue.Head - 1);
         Queue.Data (Queue.Head) := Item;
         Queue.Count             := Queue.Count + 1;
      end if;
   end Add_To_Head;

end SAL.Gen_Bounded_Definite_Queues;
