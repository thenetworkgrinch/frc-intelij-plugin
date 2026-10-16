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
import edu.wpi.first.math.system.plant.LinearSystemId;
import edu.wpi.first.wpilibj.RobotController;
import edu.wpi.first.wpilibj.simulation.DifferentialDrivetrainSim;
import edu.wpi.first.wpilibj.simulation.DifferentialDrivetrainSim.KitbotGearing;
import edu.wpi.first.wpilibj.simulation.DriverStationSim;
import edu.wpi.first.wpilibj.simulation.PWMSim;
import edu.wpi.first.wpilibj.simulation.SimHooks;
import edu.wpi.first.wpilibj.simulation.UltrasonicSim;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.parallel.ResourceLock;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

@ResourceLock("timing")
class UltrasonicPIDTest {
  private final DCMotor m_gearbox = DCMotor.getFalcon500(2);
  private static final double kGearing = KitbotGearing.k10p71.value;
  public static final double kvVoltSecondsPerMeter = 1.98;
  public static final double kaVoltSecondsSquaredPerMeter = 0.2;
  private static final double kvVoltSecondsPerRadian = 1.5;
  private static final double kaVoltSecondsSquaredPerRadian = 0.3;
  private static final double kWheelDiameterMeters = 0.15;
  private static final double kTrackwidthMeters = 0.7;

  private Robot m_robot;
  private Thread m_thread;

  private DifferentialDrivetrainSim m_driveSim;
  private PWMSim m_leftMotorSim;
  private PWMSim m_rightMotorSim;
  private UltrasonicSim m_ultrasonicSim;
  private SimPeriodicBeforeCallback m_callback;

  // distance between the robot's starting position and the object
  // we will update this in a moment
  private double m_startToObject = Double.POSITIVE_INFINITY;
  private double m_distanceMM;

  // We're not using @BeforeEach so m_startToObject gets initialized properly
  private void startThread() {
    HAL.initialize(500, 0);
    SimHooks.pauseTiming();
    DriverStationSim.resetData();
    m_robot = new Robot();
    m_thread = new Thread(m_robot::startCompetition);
    m_driveSim =
        new DifferentialDrivetrainSim(
            LinearSystemId.identifyDrivetrainSystem(
                kvVoltSecondsPerMeter,
                kaVoltSecondsSquaredPerMeter,
                kvVoltSecondsPerRadian,
                kaVoltSecondsSquaredPerRadian),
            m_gearbox,
            kGearing,
            kTrackwidthMeters,
            kWheelDiameterMeters / 2.0,
            null);
    m_ultrasonicSim = new UltrasonicSim(Robot.ULTRASONIC_PING_PORT, Robot.ULTRASONIC_ECHO_PORT);
    m_leftMotorSim = new PWMSim(Robot.LEFT_MOTOR_PORT);
    m_rightMotorSim = new PWMSim(Robot.RIGHT_MOTOR_PORT);

    m_callback =
        HAL.registerSimPeriodicBeforeCallback(
            () -> {
              m_driveSim.setInputs(
                  m_leftMotorSim.getSpeed() * RobotController.getBatteryVoltage(),
                  m_rightMotorSim.getSpeed() * RobotController.getBatteryVoltage());
              m_driveSim.update(0.02);

              double startingDistance = m_startToObject;
              double range = m_driveSim.getLeftPositionMeters() - startingDistance;

              m_ultrasonicSim.setRangeMeters(range);
              m_distanceMM = range * 1.0e3;
            });

    m_thread.start();
    SimHooks.stepTiming(0.0); // Wait for Notifiers
    SimHooks.stepTiming(0.02); // Have once iteration on disabled
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
    m_leftMotorSim.resetData();
    m_rightMotorSim.resetData();
  }

  @ValueSource(doubles = {1.3, 0.5, 5.0})
  @ParameterizedTest
  void autoTest(double distance) {
    // set up distance
    {
      m_startToObject = distance;
    }
    startThread();

    // auto init
    {
      DriverStationSim.setAutonomous(true);
      DriverStationSim.setEnabled(true);
      DriverStationSim.notifyNewData();

      assertTrue(m_leftMotorSim.getInitialized());
      assertTrue(m_rightMotorSim.getInitialized());
    }

    {
      SimHooks.stepTiming(5.0);

      assertEquals(Robot.HOLD_DISTANCE_MILLIMETERS, m_distanceMM, 10.0);
    }
  }
}
