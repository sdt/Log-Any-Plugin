Log::Any::Plugin is intended as a companion to the Jonathan Swartz's excellent [Log::Any](http://search.cpan.org/~jswartz/Log-Any-0.13/lib/Log/Any.pm) module.

It provides methods for augmenting arbitrary instances of [Log::Any::Adapters](http://search.cpan.org/~jswartz/Log-Any-Adapter-0.03/lib/Log/Any/Adapter.pm).

Log::Any::Plugins work much in the same manner as [Moose 'around' modifiers](http://search.cpan.org/~doy/Moose-2.0202/lib/Moose/Manual/MethodModifiers.pod) to augment logging behaviour of pre-existing adapters.


Many of the Log::Any::Adapters have extended functionality, such as being able to selectively disable various log levels, or to handle multiple arguments.

In order for Log::Any to be truly 'any', only the common subset of adapter functionality can be used. Any specific adapter functionality must be avoided if there is a possibility of using a different adapter at a later date.

Log::Any::Plugins provide a method to augment adapters with missing functionality so that a superset of adapter functionality can be used. They also allow features to effectively be added to Log::Any without polluting the actual source base.
