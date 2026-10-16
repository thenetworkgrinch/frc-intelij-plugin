<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
${data.copyright}

package ${data.basePackage};

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import edu.wpi.first.hal.HAL;
import edu.wpi.first.math.util.Units;
import edu.wpi.first.wpilibj.Preferences;
import edu.wpi.first.wpilibj.simulation.DriverStationSim;
import edu.wpi.first.wpilibj.simulation.EncoderSim;
import edu.wpi.first.wpilibj.simulation.JoystickSim;
import edu.wpi.first.wpilibj.simulation.PWMSim;
import edu.wpi.first.wpilibj.simulation.RoboRioSim;
import edu.wpi.first.wpilibj.simulation.SimHooks;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.parallel.ResourceLock;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

@ResourceLock("timing")
class ArmSimulationTest {
  private Robot m_robot;
  private Thread m_thread;

  private PWMSim m_motorSim;
  private EncoderSim m_encoderSim;
  private JoystickSim m_joystickSim;

  @BeforeEach
  void startThread() {
    HAL.initialize(500, 0);
    SimHooks.pauseTiming();
    DriverStationSim.resetData();
    m_robot = new Robot();
    m_thread = new Thread(m_robot::startCompetition);
    m_encoderSim = EncoderSim.createForChannel(Constants.ENCODER_A_CHANNEL);
    m_motorSim = new PWMSim(Constants.MOTOR_PORT);
    m_joystickSim = new JoystickSim(Constants.JOYSTICK_PORT);

    m_thread.start();
    SimHooks.stepTiming(0.0); // Wait for Notifiers
  }

  @AfterEach
  void stopThread() {
    m_robot.endCompetition();
    try {
      m_thread.interrupt();
      m_thread.join();
    } catch (InterruptedException ex) {
      Thread.currentThread().interrupt();
    }
    m_robot.close();
    m_encoderSim.resetData();
    m_motorSim.resetData();
    Preferences.remove(Constants.ARM_P_KEY);
    Preferences.remove(Constants.ARM_POSITION_KEY);
    Preferences.removeAll();
    RoboRioSim.resetData();
    DriverStationSim.resetData();
    DriverStationSim.notifyNewData();
  }

  @ValueSource(doubles = {Constants.DEFAULT_ARM_SETPOINT_DEGREES, 25.0, 50.0})
  @ParameterizedTest
  void teleopTest(double setpoint) {
    assertTrue(Preferences.containsKey(Constants.ARM_POSITION_KEY));
    assertTrue(Preferences.containsKey(Constants.ARM_P_KEY));
    Preferences.setDouble(Constants.ARM_POSITION_KEY, setpoint);
    assertEquals(setpoint, Preferences.getDouble(Constants.ARM_POSITION_KEY, Double.NaN));
    // teleop init
    {
      DriverStationSim.setAutonomous(false);
      DriverStationSim.setEnabled(true);
      DriverStationSim.notifyNewData();

      assertTrue(m_motorSim.getInitialized());
      assertTrue(m_encoderSim.getInitialized());
    }

    {
      // advance 150 timesteps
      SimHooks.stepTiming(3);

      // Ensure arm is still at minimum angle.
      assertEquals(Constants.MIN_ANGLE_RADS, m_encoderSim.getDistance(), 2.0);
    }

    {
      // Press button to reach setpoint
      m_joystickSim.setTrigger(true);
      m_joystickSim.notifyNewData();

      // advance 75 timesteps
      SimHooks.stepTiming(1.5);

      assertEquals(setpoint, Units.radiansToDegrees(m_encoderSim.getDistance()), 2.0);

      // advance 25 timesteps to see setpoint is held.
      SimHooks.stepTiming(0.5);

      assertEquals(setpoint, Units.radiansToDegrees(m_encoderSim.getDistance()), 2.0);
    }

    {
      // Unpress the button to go back down
      m_joystickSim.setTrigger(false);
      m_joystickSim.notifyNewData();

      // advance 150 timesteps
      SimHooks.stepTiming(3.0);

      assertEquals(Constants.MIN_ANGLE_RADS, m_encoderSim.getDistance(), 2.0);
    }

    {
      // Press button to go back up
      m_joystickSim.setTrigger(true);
      m_joystickSim.notifyNewData();

      // advance 75 timesteps
      SimHooks.stepTiming(1.5);

      assertEquals(setpoint, Units.radiansToDegrees(m_encoderSim.getDistance()), 2.0);

      // advance 25 timesteps to see setpoint is held.
      SimHooks.stepTiming(0.5);

      assertEquals(setpoint, Units.radiansToDegrees(m_encoderSim.getDistance()), 2.0);
    }

    {
      // Disable
      DriverStationSim.setAutonomous(false);
      DriverStationSim.setEnabled(false);
      DriverStationSim.notifyNewData();

      // advance 75 timesteps
      SimHooks.stepTiming(3.5);

      assertEquals(0.0, m_motorSim.getSpeed(), 0.01);
      assertEquals(Constants.MIN_ANGLE_RADS, m_encoderSim.getDistance(), 2.0);
    }
  }
}
