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
import edu.wpi.first.wpilibj.simulation.DriverStationSim;
import edu.wpi.first.wpilibj.simulation.EncoderSim;
import edu.wpi.first.wpilibj.simulation.JoystickSim;
import edu.wpi.first.wpilibj.simulation.PWMSim;
import edu.wpi.first.wpilibj.simulation.RoboRioSim;
import edu.wpi.first.wpilibj.simulation.SimHooks;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.parallel.ResourceLock;

@ResourceLock("timing")
class ElevatorSimulationTest {
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
    RoboRioSim.resetData();
    DriverStationSim.resetData();
    DriverStationSim.notifyNewData();
  }

  @Test
  void teleopTest() {
    // teleop init
    {
      DriverStationSim.setAutonomous(false);
      DriverStationSim.setEnabled(true);
      DriverStationSim.notifyNewData();

      assertTrue(m_motorSim.getInitialized());
      assertTrue(m_encoderSim.getInitialized());
    }

    {
      // advance 50 timesteps
      SimHooks.stepTiming(1);

      // Ensure elevator is still at 0.
      assertEquals(0.0, m_encoderSim.getDistance(), 0.05);
    }

    {
      // Press button to reach setpoint
      m_joystickSim.setTrigger(true);
      m_joystickSim.notifyNewData();

      // advance 75 timesteps
      SimHooks.stepTiming(1.5);

      assertEquals(Constants.SETPOINT_METERS, m_encoderSim.getDistance(), 0.05);

      // advance 25 timesteps to see setpoint is held.
      SimHooks.stepTiming(0.5);

      assertEquals(Constants.SETPOINT_METERS, m_encoderSim.getDistance(), 0.05);
    }

    {
      // Unpress the button to go back down
      m_joystickSim.setTrigger(false);
      m_joystickSim.notifyNewData();

      // advance 75 timesteps
      SimHooks.stepTiming(1.5);

      assertEquals(0.0, m_encoderSim.getDistance(), 0.05);
    }

    {
      // Press button to go back up
      m_joystickSim.setTrigger(true);
      m_joystickSim.notifyNewData();

      // advance 75 timesteps
      SimHooks.stepTiming(1.5);

      assertEquals(Constants.SETPOINT_METERS, m_encoderSim.getDistance(), 0.05);

      // advance 25 timesteps to see setpoint is held.
      SimHooks.stepTiming(0.5);

      assertEquals(Constants.SETPOINT_METERS, m_encoderSim.getDistance(), 0.05);
    }

    {
      // Disable
      DriverStationSim.setAutonomous(false);
      DriverStationSim.setEnabled(false);
      DriverStationSim.notifyNewData();

      // advance 75 timesteps
      SimHooks.stepTiming(1.5);

      assertEquals(0.0, m_motorSim.getSpeed(), 0.05);
      assertEquals(0.0, m_encoderSim.getDistance(), 0.05);
    }
  }
}
