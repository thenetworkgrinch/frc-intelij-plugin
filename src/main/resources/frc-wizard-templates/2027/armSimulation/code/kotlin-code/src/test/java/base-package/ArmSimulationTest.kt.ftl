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

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.parallel.ResourceLock
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.ValueSource
import org.wpilib.hardware.hal.HAL
import org.wpilib.hardware.hal.RobotMode
import org.wpilib.math.util.Units
import org.wpilib.preferences.Preferences
import org.wpilib.simulation.DriverStationSim
import org.wpilib.simulation.EncoderSim
import org.wpilib.simulation.JoystickSim
import org.wpilib.simulation.PWMMotorControllerSim
import org.wpilib.simulation.RoboRioSim
import org.wpilib.simulation.SimHooks

/**
 * Tests the arm simulation program by running the robot in simulation and driving it with a simulated joystick.
 *
 * Since the robot is a Kotlin `object` (a singleton), it can only be created and started once per test run.
 * So the robot is started once for all the tests in this class (in [startRobot]) and stopped once after them
 * (in [stopRobot]); each test resets the driver station and joystick state in [resetDriverStation].
 */
@ResourceLock("timing")
class ArmSimulationTest
{
    companion object
    {
        private lateinit var thread: Thread

        private lateinit var motorSim: PWMMotorControllerSim
        private lateinit var encoderSim: EncoderSim
        private lateinit var joystickSim: JoystickSim

        @JvmStatic
        @BeforeAll
        fun startRobot()
        {
            HAL.initialize()
            SimHooks.pauseTiming()
            SimHooks.setProgramStarted(false)
            DriverStationSim.resetData()
            // Referencing the robot object for the first time creates it (and so its hardware).
            val robot = [=data.robotClassSimpleName]
            thread = Thread(robot::startCompetition)
            encoderSim = EncoderSim.createForChannel(Constants.ENCODER_A_CHANNEL)
            motorSim = PWMMotorControllerSim(Constants.MOTOR_PORT)
            joystickSim = JoystickSim(Constants.JOYSTICK_PORT)

            thread.start()
            SimHooks.waitForProgramStart()
        }

        @JvmStatic
        @AfterAll
        fun stopRobot()
        {
            [=data.robotClassSimpleName].endCompetition()
            try
            {
                thread.interrupt()
                thread.join()
            }
            catch (ex: InterruptedException)
            {
                Thread.currentThread().interrupt()
            }
            [=data.robotClassSimpleName].close()
            encoderSim.resetData()
            Preferences.remove(Constants.ARM_P_KEY)
            Preferences.remove(Constants.ARM_POSITION_KEY)
            Preferences.removeAll()
            RoboRioSim.resetData()
            DriverStationSim.resetData()
            DriverStationSim.notifyNewData()
        }
    }

    @BeforeEach
    fun resetDriverStation()
    {
        // Start each test disabled, with the joystick trigger released.
        DriverStationSim.setEnabled(false)
        DriverStationSim.notifyNewData()
        joystickSim.setTrigger(false)
        joystickSim.notifyNewData()
    }

    @AfterEach
    fun disableRobot()
    {
        DriverStationSim.setEnabled(false)
        DriverStationSim.notifyNewData()
    }

    @ValueSource(doubles = [Constants.DEFAULT_ARM_SETPOINT_DEGREES, 25.0, 50.0])
    @ParameterizedTest
    fun teleopTest(setpoint: Double)
    {
        assertTrue(Preferences.containsKey(Constants.ARM_POSITION_KEY))
        assertTrue(Preferences.containsKey(Constants.ARM_P_KEY))
        Preferences.setDouble(Constants.ARM_POSITION_KEY, setpoint)
        assertEquals(setpoint, Preferences.getDouble(Constants.ARM_POSITION_KEY, Double.NaN))

        // teleop init
        DriverStationSim.setRobotMode(RobotMode.TELEOPERATED)
        DriverStationSim.setEnabled(true)
        DriverStationSim.notifyNewData()

        assertTrue(encoderSim.initialized)

        // advance 150 timesteps
        SimHooks.stepTiming(3.0)

        // Ensure arm is still at minimum angle.
        assertEquals(Constants.MIN_ANGLE_RADS, encoderSim.distance, 2.0)

        // Press button to reach setpoint
        joystickSim.setTrigger(true)
        joystickSim.notifyNewData()

        // advance 75 timesteps
        SimHooks.stepTiming(1.5)

        assertEquals(setpoint, Units.radiansToDegrees(encoderSim.distance), 2.0)

        // advance 25 timesteps to see setpoint is held.
        SimHooks.stepTiming(0.5)

        assertEquals(setpoint, Units.radiansToDegrees(encoderSim.distance), 2.0)

        // Unpress the button to go back down
        joystickSim.setTrigger(false)
        joystickSim.notifyNewData()

        // advance 150 timesteps
        SimHooks.stepTiming(3.0)

        assertEquals(Constants.MIN_ANGLE_RADS, encoderSim.distance, 2.0)

        // Press button to go back up
        joystickSim.setTrigger(true)
        joystickSim.notifyNewData()

        // advance 75 timesteps
        SimHooks.stepTiming(1.5)

        assertEquals(setpoint, Units.radiansToDegrees(encoderSim.distance), 2.0)

        // advance 25 timesteps to see setpoint is held.
        SimHooks.stepTiming(0.5)

        assertEquals(setpoint, Units.radiansToDegrees(encoderSim.distance), 2.0)

        // Disable
        DriverStationSim.setEnabled(false)
        DriverStationSim.notifyNewData()

        // advance 75 timesteps
        SimHooks.stepTiming(3.5)

        assertEquals(0.0, motorSim.throttle, 0.01)
        assertEquals(Constants.MIN_ANGLE_RADS, encoderSim.distance, 2.0)
    }
}
