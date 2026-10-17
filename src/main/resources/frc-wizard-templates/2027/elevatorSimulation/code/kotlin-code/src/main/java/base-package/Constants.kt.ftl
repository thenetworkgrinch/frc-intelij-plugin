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

    const val ELEVATOR_KP = 5.0
    const val ELEVATOR_KI = 0.0
    const val ELEVATOR_KD = 0.0

    const val ELEVATOR_KS = 0.0 // volts (V)
    const val ELEVATOR_KG = 0.762 // volts (V)
    const val ELEVATOR_KV = 0.762 // volt per velocity (V/(m/s))
    const val ELEVATOR_KA = 0.0 // volt per acceleration (V/(m/s²))

    const val ELEVATOR_GEARING = 10.0
    val ELEVATOR_DRUM_RADIUS = Units.inchesToMeters(2.0)
    const val CARRIAGE_MASS = 4.0 // kg

    const val SETPOINT = 0.75 // m
    // Encoder is reset to measure 0 at the bottom, so minimum height is 0.
    const val MIN_ELEVATOR_HEIGHT = 0.0 // m
    const val MAX_ELEVATOR_HEIGHT = 1.25 // m

    // distance per pulse = (distance per revolution) / (pulses per revolution)
    //  = (Pi * D) / ppr
    val ELEVATOR_ENCODER_DIST_PER_PULSE = 2.0 * Math.PI * ELEVATOR_DRUM_RADIUS / 4096
}
