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

import [=data.basePackage].Constants.IntakeConstants
import org.wpilib.drivers.motor.PWMSparkMax
import org.wpilib.hardware.bus.CANPort
import org.wpilib.hardware.pneumatic.DoubleSolenoid
import org.wpilib.hardware.pneumatic.PneumaticsModuleType

class Intake : AutoCloseable
{
    private val motor = PWMSparkMax(IntakeConstants.MOTOR_PORT)
    private val piston = DoubleSolenoid(
        CANPort.CAN_S0,
        PneumaticsModuleType.CTRE_PCM,
        IntakeConstants.PISTON_FWD_CHANNEL,
        IntakeConstants.PISTON_REV_CHANNEL
    )

    fun deploy()
    {
        piston.set(DoubleSolenoid.Value.FORWARD)
    }

    fun retract()
    {
        piston.set(DoubleSolenoid.Value.REVERSE)
        motor.throttle = 0.0 // turn off the motor
    }

    fun activate(velocity: Double)
    {
        if (isDeployed)
        {
            motor.throttle = velocity
        }
        else
        { // if piston isn't open, do nothing
            motor.throttle = 0.0
        }
    }

    val isDeployed: Boolean
        get() = piston.get() == DoubleSolenoid.Value.FORWARD

    override fun close()
    {
        piston.close()
        motor.close()
    }
}
