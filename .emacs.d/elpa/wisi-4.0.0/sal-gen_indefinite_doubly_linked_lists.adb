--  Abstract :
--
--  see spec
--
--  Copyright (C) 2018 - 2022 Free Software Foundation, Inc.
--
--  This library is free software; you can redistribute it and/or
--  modify it under terms of the GNU General Public License as
--  published by the Free Software Foundation; either version 3, or (at
--  your option) any later version. This library is distributed in the
--  hope that it will be useful, but WITHOUT ANY WARRANTY; without even
--  the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
--  PURPOSE. See the GNU General Public License for more details. You
--  should have received a copy of the GNU General Public License
--  distributed with this program; see file COPYING. If not, write to
--  the Free Software Foundation, 59 Temple Place - Suite 330, Boston,
--  MA 02111-1307, USA.
--
--  As a special exception under Section 7 of GPL version 3, you are granted
--  additional permissions described in the GCC Runtime Library Exception,
--  version 3.1, as published by the Free Software Foundation.

pragma License (Modified_GPL);

package body SAL.Gen_Indefinite_Doubly_Linked_Lists is

   ---------
   --  Public operations, declaration order.

   overriding
   procedure Adjust (Container : in out List)
   is
      Source   : Node_Access := Container.Head;
      New_Node : Node_Access;
   begin
      if Source = null then
         return;
      end if;

      Container.Tail := null;

      loop
         New_Node := new Node_Type'
           (Element => new Element_Type'(Source.Element.all),
            Next    => null,
            Prev    => Container.Tail);
         if Container.Tail = null then
            Container.Head := New_Node;
            Container.Tail := New_Node;
         else
            Container.Tail.Next := New_Node;
            Container.Tail      := New_Node;
         end if;
         Source := Source.Next;
         exit when Source = null;
      end loop;
   end Adjust;

   overriding
   procedure Finalize (Container : in out List)
   is
      Next : Node_Access := Container.Head;
   begin
      loop
         exit when Next = null;
         Next := Container.Head.Next;
         Free (Container.Head.Element);
         Free (Container.Head);
         Container.Head := Next;
      end loop;
      Container.Tail  := null;
      Container.Count := 0;
   end Finalize;

   function Length (Container : in List) return SAL.Base_Peek_Type
   is begin
      return Container.Count;
   end Length;

   procedure Append (Container : in out List; Element : in Element_Type)
   is
      New_Node : constant Node_Access := new Node_Type'
        (Element => new Element_Type'(Element),
         Prev    => Container.Tail,
         Next    => null);
   begin
      if Container.Tail = null then
         Container.Head := New_Node;
         Container.Tail := New_Node;
      else
         Container.Tail.Next := New_Node;
         Container.Tail      := New_Node;
      end if;
      Container.Count := Container.Count + 1;
   end Append;

   procedure Prepend (Container : in out List; Element : in Element_Type)
   is
      New_Node : constant Node_Access := new Node_Type'
        (Element => new Element_Type'(Element),
         Prev    => null,
         Next    => Container.Head);
   begin
      if Container.Tail = null then
         Container.Head := New_Node;
         Container.Tail := New_Node;
      else
         Container.Head.Prev := New_Node;
         Container.Head      := New_Node;
      end if;
      Container.Count := Container.Count + 1;
   end Prepend;

   function To_List (Element : in Element_Type) return List
   is begin
      return Result : List do
         Result.Append (Element);
      end return;
   end To_List;

   function Has_Element (Position : in Cursor) return Boolean
   is begin
      return Position.Ptr /= null;
   end Has_Element;

   function First (Container : in List) return Cursor
   is begin
      if Container.Head = null then
         return (Ptr => null);
      else
         return (Ptr => Container.Head);
      end if;
   end First;

   function Last (Container : in List) return Cursor
   is begin
      if Container.Tail = null then
         return (Ptr => null);
      else
         return (Ptr => Container.Tail);
      end if;
   end Last;

   procedure Next (Position : in out Cursor)
   is begin
      if Position.Ptr /= null then
         if Position.Ptr.Next = null then
            Position.Ptr := null;
         else
            Position.Ptr := Position.Ptr.Next;
         end if;
      end if;
   end Next;

   function Next (Position : in Cursor) return Cursor
   is begin
      if Position.Ptr = null then
         return Position;
      else
         if Position.Ptr.Next = null then
            return (Ptr => null);
         else
            return (Ptr => Position.Ptr.Next);
         end if;
      end if;
   end Next;

   function Previous (Position : in Cursor) return Cursor
   is begin
      if Position.Ptr = null then
         return Position;
      else
         if Position.Ptr.Prev = null then
            return (Ptr => null);
         else
            return (Ptr => Position.Ptr.Prev);
         end if;
      end if;
   end Previous;

   function Element (Position : in Cursor) return Element_Type
   is begin
      return Position.Ptr.Element.all;
   end Element;

   function Append (Container : in out List; Element : in Element_Type) return Cursor
   is begin
      Append (Container, Element);
      return (Ptr => Container.Tail);
   end Append;

   procedure Delete (Container : in out List; Position : in out Cursor)
   is
      Node : Node_Access renames Position.Ptr;
   begin
      if Node.Next = null then
         Container.Tail := Node.Prev;
      else
         Node.Next.Prev := Node.Prev;
      end if;
      if Node.Prev = null then
         Container.Head := Node.Next;
      else
         Node.Prev.Next := Node.Next;
      end if;
      Free (Node.Element);
      Free (Node);
      Position        := (Ptr => null);
      Container.Count := Container.Count - 1;
   end Delete;

   function Unchecked_Ref (Position : in Cursor) return access Element_Type
   is begin
      return Position.Ptr.Element;
   end Unchecked_Ref;

   function Constant_Ref (Position : in Cursor) return Constant_Reference_Type
   is begin
      return (Element => Position.Ptr.all.Element, Dummy => 1);
   end Constant_Ref;

   function Constant_Reference (Container : in List; Position : in Cursor) return Constant_Reference_Type
   is begin
      return (Element => Position.Ptr.Element, Dummy => 1);
   end Constant_Reference;

   function Variable_Reference (Container : in List; Position : in Cursor) return Variable_Reference_Type
   is begin
      return (Element => Position.Ptr.Element, Dummy => 1);
   end Variable_Reference;

   function Variable_Ref (Position : in Cursor) return Variable_Reference_Type
   is begin
      return (Element => Position.Ptr.Element, Dummy => 1);
   end Variable_Ref;

   function Iterate (Container : aliased in List) return Iterator_Interfaces.Reversible_Iterator'Class
   is begin
      return Iterator'(Container => Container'Access);
   end Iterate;

   overriding function First (Object : Iterator) return Cursor
   is begin
      return First (Object.Container.all);
   end First;

   overriding function Last  (Object : Iterator) return Cursor
   is begin
      return Last (Object.Container.all);
   end Last;

   overriding function Next (Object : in Iterator; Position : in Cursor) return Cursor
   is
      pragma Unreferenced (Object);
   begin
      return Next (Position);
   end Next;

   overriding function Previous (Object : in Iterator; Position : in Cursor) return Cursor
   is
      pragma Unreferenced (Object);
   begin
      return Previous (Position);
   end Previous;

end SAL.Gen_Indefinite_Doubly_Linked_Lists;
