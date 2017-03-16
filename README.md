# EncoderMultiplierV2

An assembly translation of the Arduino based encoder translators with a few extra features.

This code was written in Atmel Studio 6 targeted for the ATTINY85.

## Why?

Increasing the frequency of the frequency that the Talon SRX reads
allows the use of a lower sample time and a shorter filter length,
leading to less input lag and loops that are easier tune.

The quadrature output allows for this to be a drop in solution
with the only scaling constants needing to be changed.

The frequency multiplication is 25x.

There is a minimum and maximum frequency output so the encoder multipliers
will read a fixed RPM when the system that it is measuring is not moving.

NOTE: This code does not preserve position information, only velocity.
