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

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.parallel.ResourceLock;
import org.wpilib.hardware.hal.HAL;
import org.wpilib.hardware.hal.RobotMode;
import org.wpilib.simulation.DriverStationSim;
import org.wpilib.simulation.EncoderSim;
import org.wpilib.simulation.JoystickSim;
import org.wpilib.simulation.PWMMotorControllerSim;
import org.wpilib.simulation.RoboRioSim;
import org.wpilib.simulation.SimHooks;

@ResourceLock("timing")
class ElevatorSimulationTest {
  private Robot robot;
  private Thread thread;

  private PWMMotorControllerSim motorSim;
  private EncoderSim encoderSim;
  private JoystickSim joystickSim;

  @BeforeEach
  void startThread() {
    HAL.initialize();
    SimHooks.pauseTiming();
    SimHooks.setProgramStarted(false);
    DriverStationSim.resetData();
    robot = new Robot();
    thread = new Thread(robot::startCompetition);
    encoderSim = EncoderSim.createForChannel(Constants.ENCODER_A_CHANNEL);
    motorSim = new PWMMotorControllerSim(Constants.MOTOR_PORT);
    joystickSim = new JoystickSim(Constants.JOYSTICK_PORT);

    thread.start();
    SimHooks.waitForProgramStart();
  }

  @AfterEach
  void stopThread() {
    robot.endCompetition();
    try {
      thread.interrupt();
      thread.join();
    } catch (InterruptedException ex) {
      Thread.currentThread().interrupt();
    }
    robot.close();
    encoderSim.resetData();
    RoboRioSim.resetData();
    DriverStationSim.resetData();
    DriverStationSim.notifyNewData();
  }

  @Test
  void teleopTest() {
    // teleop init
    {
      DriverStationSim.setRobotMode(RobotMode.TELEOPERATED);
      DriverStationSim.setEnabled(true);
      DriverStationSim.notifyNewData();

      assertTrue(encoderSim.getInitialized());
    }

    {
      // advance 50 timesteps
      SimHooks.stepTiming(1);

      // Ensure elevator is still at 0.
      assertEquals(0.0, encoderSim.getDistance(), 0.05);
    }

    {
      // Press button to reach setpoint
      joystickSim.setTrigger(true);
      joystickSim.notifyNewData();

      // advance 75 timesteps
      SimHooks.stepTiming(1.5);

      assertEquals(Constants.SETPOINT, encoderSim.getDistance(), 0.05);

      // advance 25 timesteps to see setpoint is held.
      SimHooks.stepTiming(0.5);

      assertEquals(Constants.SETPOINT, encoderSim.getDistance(), 0.05);
    }

    {
      // Unpress the button to go back down
      joystickSim.setTrigger(false);
      joystickSim.notifyNewData();

      // advance 75 timesteps
      SimHooks.stepTiming(1.5);

      assertEquals(0.0, encoderSim.getDistance(), 0.05);
    }

    {
      // Press button to go back up
      joystickSim.setTrigger(true);
      joystickSim.notifyNewData();

      // advance 75 timesteps
      SimHooks.stepTiming(1.5);

      assertEquals(Constants.SETPOINT, encoderSim.getDistance(), 0.05);

      // advance 25 timesteps to see setpoint is held.
      SimHooks.stepTiming(0.5);

      assertEquals(Constants.SETPOINT, encoderSim.getDistance(), 0.05);
    }

    {
      // Disable
      DriverStationSim.setEnabled(false);
      DriverStationSim.notifyNewData();

      // advance 75 timesteps
      SimHooks.stepTiming(1.5);

      assertEquals(0.0, motorSim.getThrottle(), 0.05);
      assertEquals(0.0, encoderSim.getDistance(), 0.05);
    }
  }
}
