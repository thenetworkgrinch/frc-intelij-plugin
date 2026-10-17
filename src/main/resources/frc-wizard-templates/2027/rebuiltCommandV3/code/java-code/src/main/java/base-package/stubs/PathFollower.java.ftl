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

package ${data.basePackage}.stubs;

import org.wpilib.math.kinematics.ChassisVelocities;

/**
 * A stub interface for an API that could plausibly follow a path. No WPILib code exists for this;
 * if you want to follow paths on a real robot, use a third-party library provided by the FRC
 * programming community.
 */
public interface PathFollower {
  /**
   * Gets the next chassis velocities from the path.
   *
   * @return the next chassis velocities
   */
  ChassisVelocities next();

  /**
   * Checks if the robot has reached the end of the path.
   *
   * @return true if the robot has reached the end of the path, false otherwise
   */
  boolean isDone();

  /**
   * Loads a path from a file in the deploy directory. This is a stub implementation as an example;
   * a real robot program would use a third-party path following library.
   *
   * @param pathName The name of the path file to load.
   * @return A PathFollower instance that can follow the loaded path.
   */
  static PathFollower load(String pathName) {
    return new PathFollower() {
      @Override
      public ChassisVelocities next() {
        return new ChassisVelocities();
      }

      @Override
      public boolean isDone() {
        return true;
      }
    };
  }
}
