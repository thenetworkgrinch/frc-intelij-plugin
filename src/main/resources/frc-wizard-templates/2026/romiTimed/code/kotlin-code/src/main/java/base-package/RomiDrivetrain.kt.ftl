<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    IMPORTANT: This tempolate uses alternate square bracket interpolation syntax
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

import edu.wpi.first.wpilibj.Encoder
import edu.wpi.first.wpilibj.drive.DifferentialDrive
import edu.wpi.first.wpilibj.motorcontrol.Spark

// By making the drivetrain an object, we ensure there is only ever one instance of it
object RomiDrivetrain
{
    private const val COUNTS_PER_REVOLUTION = 1440.0
    private const val WHEEL_DIAMETER_INCH = 2.75591 // 70 mm

    // The Romi has the left and right motors set to PWM channels 0 and 1 respectively
    private val leftMotor = Spark(0)
    private val rightMotor = Spark(1)

    // The Romi has onboard encoders that are hardcoded to use DIO pins 4/5 and 6/7 for the left and right
    private val leftEncoder = Encoder(4, 5)
    private val rightEncoder = Encoder(6, 7)

    // Set up the differential drive controller
    private val diffDrive = DifferentialDrive(
        { value -> leftMotor.set(value) },
        { value -> rightMotor.set(value) }
                                             )

    val leftDistanceInch: Double
        get() = leftEncoder.distance
    val rightDistanceInch: Double
        get() = rightEncoder.distance

    init
    {
        // Initialize the RomiDrivetrain.
        // Use inches as unit for encoder distances
        leftEncoder.distancePerPulse = Math.PI * WHEEL_DIAMETER_INCH / COUNTS_PER_REVOLUTION
        rightEncoder.distancePerPulse = Math.PI * WHEEL_DIAMETER_INCH / COUNTS_PER_REVOLUTION
        resetEncoders()
        // Invert right side since motor is flipped
        rightMotor.inverted=true
    }

    fun arcadeDrive(xAxisSpeed: Double, zAxisRotate: Double) = diffDrive.arcadeDrive(xAxisSpeed, zAxisRotate)

    fun resetEncoders()
    {
        leftEncoder.reset()
        rightEncoder.reset()
    }
}