<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    IMPORTANT: This template uses alternate square bracket interpolation syntax
               For example:
                    [=data.robotClassSimpleName]
               rather than:
                    ${data.robotClassSimpleName}
               so as to not clash with Kotlin string templates syntax
               The option to use that can't be set in the template, but has to be set as an
               option on the Configuration object in the code. Note that this only affects interpolation
               syntax, and *NOT* Tag syntax. So we will still use `<#if isSuchAndSuch>` and not `[#if isSuchAndSuch]`.
               Tag syntax can be changed if desired, but we are not.
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
package [=data.basePackage]

import org.wpilib.math.util.Units

object Constants
{
    const val MOTOR_PORT = 0
    const val ENCODER_A_CHANNEL = 0
    const val ENCODER_B_CHANNEL = 1
    const val JOYSTICK_PORT = 0

    const val ELEVATOR_KP = 0.75
    const val ELEVATOR_KI = 0.0
    const val ELEVATOR_KD = 0.0

    const val ELEVATOR_MAX_V = 10.0 // volts (V)
    const val ELEVATOR_KS = 0.0 // volts (V)
    const val ELEVATOR_KG = 0.62 // volts (V)
    const val ELEVATOR_KV = 3.9 // volts (V)
    const val ELEVATOR_KA = 0.06 // volts (V)

    const val ELEVATOR_GEARING = 5.0
    val ELEVATOR_DRUM_RADIUS = Units.inchesToMeters(1.0)
    val CARRIAGE_MASS = Units.lbsToKilograms(12.0) // kg

    val SETPOINT = Units.inchesToMeters(42.875)
    val LOWERK_SETPOINT = Units.inchesToMeters(15.0)
    // Encoder is reset to measure 0 at the bottom, so minimum height is 0.
    const val MIN_ELEVATOR_HEIGHT = 0.0 // m
    val MAX_ELEVATOR_HEIGHT = Units.inchesToMeters(50.0)

    // distance per pulse = (distance per revolution) / (pulses per revolution)
    //  = (Pi * D) / ppr
    val ELEVATOR_ENCODER_DIST_PER_PULSE = 2.0 * Math.PI * ELEVATOR_DRUM_RADIUS / 4096
}
