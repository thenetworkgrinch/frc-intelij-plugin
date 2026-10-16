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
import edu.wpi.first.hal.HAL.SimPeriodicBeforeCallback;
import edu.wpi.first.math.system.plant.DCMotor;
import edu.wpi.first.math.util.Units;
import edu.wpi.first.wpilibj.RobotController;
import edu.wpi.first.wpilibj.simulation.AnalogInputSim;
import edu.wpi.first.wpilibj.simulation.DriverStationSim;
import edu.wpi.first.wpilibj.simulation.ElevatorSim;
import edu.wpi.first.wpilibj.simulation.JoystickSim;
import edu.wpi.first.wpilibj.simulation.PWMSim;
import edu.wpi.first.wpilibj.simulation.SimHooks;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.parallel.ResourceLock;

@ResourceLock("timing")
class PotentiometerPIDTest {
  private final DCMotor m_elevatorGearbox = DCMotor.getVex775Pro(4);
  private static final double kElevatorGearing = 10.0;
  private static final double kElevatorDrumRadius = Units.inchesToMeters(2.0);
  private static final double kCarriageMassKg = 4.0; // kg

  private Robot m_robot;
  private Thread m_thread;

  private ElevatorSim m_elevatorSim;
  private PWMSim m_motorSim;
  private AnalogInputSim m_analogSim;
  private SimPeriodicBeforeCallback m_callback;
  private JoystickSim m_joystickSim;

  @BeforeEach
  void startThread() {
    HAL.initialize(500, 0);
    SimHooks.pauseTiming();
    DriverStationSim.resetData();
    m_robot = new Robot();
    m_thread = new Thread(m_robot::startCompetition);
    m_elevatorSim =
        new ElevatorSim(
            m_elevatorGearbox,
            kElevatorGearing,
            kCarriageMassKg,
            kElevatorDrumRadius,
            0.0,
            Robot.FULL_HEIGHT_METERS,
            true,
            0);
    m_analogSim = new AnalogInputSim(Robot.POT_CHANNEL);
    m_motorSim = new PWMSim(Robot.MOTOR_CHANNEL);
    m_joystickSim = new JoystickSim(Robot.JOYSTICK_CHANNEL);

    m_callback =
        HAL.registerSimPeriodicBeforeCallback(
            () -> {
              m_elevatorSim.setInputVoltage(
                  m_motorSim.getSpeed() * RobotController.getBatteryVoltage());
              m_elevatorSim.update(0.02);

              /*
              meters = (v / 5v) * range
              meters / range = v / 5v
              5v * (meters / range) = v
               */
              m_analogSim.setVoltage(
                  RobotController.getVoltage5V()
                      * (m_elevatorSim.getPositionMeters() / Robot.FULL_HEIGHT_METERS));
            });

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
    m_callback.close();
    m_analogSim.resetData();
    m_motorSim.resetData();
  }

  @Test
  void teleopTest() {
    // teleop init
    {
      DriverStationSim.setAutonomous(false);
      DriverStationSim.setEnabled(true);
      DriverStationSim.notifyNewData();

      assertTrue(m_motorSim.getInitialized());
      assertTrue(m_analogSim.getInitialized());
    }

    // first setpoint
    {
      // advance 50 timesteps
      SimHooks.stepTiming(1);

      assertEquals(Robot.SETPOINTS_METERS[0], m_elevatorSim.getPositionMeters(), 0.1);
    }

    // second setpoint
    {
      // press button to advance setpoint
      m_joystickSim.setTrigger(true);
      m_joystickSim.notifyNewData();

      // advance 50 timesteps
      SimHooks.stepTiming(1);

      assertEquals(Robot.SETPOINTS_METERS[1], m_elevatorSim.getPositionMeters(), 0.1);
    }

    // we need to unpress the button
    {
      m_joystickSim.setTrigger(false);
      m_joystickSim.notifyNewData();

      // advance 10 timesteps
      SimHooks.stepTiming(0.2);
    }

    // third setpoint
    {
      // press button to advance setpoint
      m_joystickSim.setTrigger(true);
      m_joystickSim.notifyNewData();

      // advance 50 timesteps
      SimHooks.stepTiming(1);

      assertEquals(Robot.SETPOINTS_METERS[2], m_elevatorSim.getPositionMeters(), 0.1);
    }

    // we need to unpress the button
    {
      m_joystickSim.setTrigger(false);
      m_joystickSim.notifyNewData();

      // advance 10 timesteps
      SimHooks.stepTiming(0.2);
    }

    // rollover: first setpoint
    {
      // press button to advance setpoint
      m_joystickSim.setTrigger(true);
      m_joystickSim.notifyNewData();

      // advance 60 timesteps
      SimHooks.stepTiming(1.2);

      assertEquals(Robot.SETPOINTS_METERS[0], m_elevatorSim.getPositionMeters(), 0.1);
    }
  }
}
