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
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.wpilib.hardware.hal.HAL
import org.wpilib.hardware.pneumatic.DoubleSolenoid
import org.wpilib.hardware.pneumatic.PneumaticsModuleType
import org.wpilib.simulation.DoubleSolenoidSim
import org.wpilib.simulation.PWMMotorControllerSim

class IntakeTest
{
    companion object
    {
        const val DELTA = 1e-2 // acceptable deviation range
    }

    private lateinit var intake: Intake
    private lateinit var simMotor: PWMMotorControllerSim
    private lateinit var simPiston: DoubleSolenoidSim

    @BeforeEach // this method will run before each test
    fun setup()
    {
        assertTrue(HAL.initialize()) // initialize the HAL, crash if failed
        intake = Intake() // create our intake
        simMotor = PWMMotorControllerSim(IntakeConstants.MOTOR_PORT) // create our simulation PWM motor controller
        simPiston = DoubleSolenoidSim(
            PneumaticsModuleType.CTRE_PCM,
            IntakeConstants.PISTON_FWD_CHANNEL,
            IntakeConstants.PISTON_REV_CHANNEL
        ) // create our simulation solenoid
    }

    @AfterEach // this method will run after each test
    fun shutdown()
    {
        intake.close() // destroy our intake object
    }

    @Test // marks this method as a test
    fun doesntWorkWhenClosed()
    {
        intake.retract() // close the intake
        intake.activate(0.5) // try to activate the motor
        assertEquals(0.0, simMotor.throttle, DELTA) // make sure that the value set to the motor is 0
    }

    @Test
    fun worksWhenOpen()
    {
        intake.deploy()
        intake.activate(0.5)
        assertEquals(0.5, simMotor.throttle, DELTA)
    }

    @Test
    fun retractTest()
    {
        intake.retract()
        assertEquals(DoubleSolenoid.Value.REVERSE, simPiston.get())
    }

    @Test
    fun deployTest()
    {
        intake.deploy()
        assertEquals(DoubleSolenoid.Value.FORWARD, simPiston.get())
    }
}
