--  Abstract :
--
--  A simple bounded sorted vector of definite items, in Spark.
--
--  Copyright (C) 2018 - 2019 Free Software Foundation, Inc.
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

generic
   type Element_Type is private;
   with function Element_Compare (Left, Right : in Element_Type) return Compare_Result;
   Capacity : in Ada.Containers.Count_Type;
package SAL.Gen_Bounded_Definite_Vectors_Sorted
  with Spark_Mode
is
   use all type Ada.Containers.Count_Type;

   type Vector is private with
     Default_Initial_Condition => Length (Vector) = 0;

   function Length (Container : in Vector) return Ada.Containers.Count_Type with
     Post => Length'Result in 0 .. Capacity;

   function Is_Full (Container : in Vector) return Boolean with
     Post => Is_Full'Result = (Length (Container) = Capacity);

   procedure Clear (Container : in out Vector) with
     Post => Length (Container) = 0;

   function First_Index (Container : in Vector) return Peek_Type
     is (Peek_Type'First) with
       Depends => (First_Index'Result => null, null => Container);

   function Last_Index (Container : in Vector) return Base_Peek_Type with
     Inline;

   function Element (Container : in Vector; Index : in Peek_Type) return Element_Type with
     Pre => Index in First_Index (Container) .. Last_Index (Container);

   function Is_Sorted (Container : in Vector) return Boolean is
     (for all I in First_Index (Container) .. Last_Index (Container) - 1 =>
        Element_Compare (Element (Container, I), Element (Container, I + 1)) in Less | Equal);

   procedure Insert
     (Container       : in out Vector;
      New_Item        : in     Element_Type;
      Ignore_If_Equal : in     Boolean := False) with
     Pre  => Length (Container) < Capacity,
     Post => Is_Sorted (Container) and
             (Length (Container) = Length (Container'Old) or
              Length (Container) = Length (Container'Old) + 1);
   --  Insert New_Item in sorted position. Items are sorted in increasing
   --  order according to Element_Compare. New_Item is inserted after
   --  Equal items, unless Ignore_If_Equal is true, in which case
   --  New_Item is not inserted.
   --
   --  The presense of Ignore_If_Equal makes it too difficult to prove
   --  whether the length did or did not increase.

private

   type Array_Type is array (Peek_Type range 1 .. Peek_Type (Capacity)) of aliased Element_Type;

   No_Index : constant Base_Peek_Type := 0;

   type Vector is record
      Elements : Array_Type;
      Last     : Base_Peek_Type := No_Index;
   end record with
     Type_Invariant => Last <= Elements'Last and Is_Sorted (Vector);
   pragma Annotate (GNATprove, Intentional, "type ""Vector"" is not fully initialized",
                    "Only items in Elements with index < Last are accessed");

end SAL.Gen_Bounded_Definite_Vectors_Sorted;
