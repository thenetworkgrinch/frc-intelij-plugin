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
package [=data.basePackage].subsystems

import org.wpilib.epilogue.Logged
import org.wpilib.command2.Command
import org.wpilib.command2.SubsystemBase
import org.wpilib.drivers.motor.PWMSparkMax
import [=data.basePackage].Constants.IntakeConstants
import org.wpilib.hardware.bus.CANPort
import org.wpilib.hardware.pneumatic.DoubleSolenoid
import org.wpilib.hardware.pneumatic.PneumaticsModuleType

@Logged
class Intake : SubsystemBase()
{
    private val motor = PWMSparkMax(IntakeConstants.MOTOR_PORT)

    // Double solenoid connected to two channels of a PCM with the default CAN ID
    private val pistons = DoubleSolenoid(
        CANPort.CAN_S0,
        PneumaticsModuleType.CTRE_PCM,
        IntakeConstants.SOLENOID_PORTS[0],
        IntakeConstants.SOLENOID_PORTS[1])

    /** Returns a command that deploys the intake, and then runs the intake motor indefinitely. */
    fun intakeCommand(): Command =
        runOnce { pistons.set(DoubleSolenoid.Value.FORWARD) }
            .andThen(run { motor.throttle = 1.0 })
            .withName("Intake")

    /** Returns a command that turns off and retracts the intake. */
    fun retractCommand(): Command =
        runOnce {
                motor.throttle = 0.0
                pistons.set(DoubleSolenoid.Value.REVERSE)
            }
            .withName("Retract")
}
