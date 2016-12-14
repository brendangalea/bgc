Datatypes are:

primitives: int, float, long, double, string, char, boolean, vecXX, matXX, optionals, tuples
collections: array, map, dict, slices
stdlib: tree, heap, stack



stdlib requirements
    randomization
    tree, heap, stack, hashmap, etc.
    channels?
    time


misc features
    mixed data type? pros / cons
    no auto-casting
    aliases
    macros
    constants are ALL_CAPS_NO_EXCEPTIONS
    ternary operator and a :? b
    private classes, etc. start with lowercase?
    yield and generators
    error handling
    complex numbers
    big numbers
    image lib
    crypto
    nested comments
    lambdas
    ARC?
    generics
    interfaces
    native c-block
    files and IO
    threading, locks, etc
    operator overloading?
    raw strings
    regex
    normal control structures
    trailing commas allowed (enforced?)
    easy iteration





code examples:


struct/shape is a tuple with named values. Can be accessed either by name
or by index
shape Student {
    string name,
    int id,
    int age,
    double gpa,
}

Student s := {}; // constructor operation
s.name <=> s[0],


components are tuples stored in a table indexed by and entity id
i.e. a system stores all components in a dictionary with ent ids as keys, and the
associated component tuple as the value


System Gravity {
    component

}


version 0.1

- objects
- vector and linalg types
- arrays
- tuples
- no memory management yet




















