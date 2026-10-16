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

import edu.wpi.first.math.StateSpaceUtil;
import edu.wpi.first.math.VecBuilder;
import edu.wpi.first.math.geometry.Pose2d;
import edu.wpi.first.math.geometry.Rotation2d;
import edu.wpi.first.math.util.Units;



/** This dummy class represents a global measurement sensor, such as a computer vision solution. */
public final class ExampleGlobalMeasurementSensor
{
    private ExampleGlobalMeasurementSensor()
    {
        // Utility class
    }
    
    
    /**
     * Get a "noisy" fake global pose reading.
     *
     * @param estimatedRobotPose The robot pose.
     */
    public static Pose2d getEstimatedGlobalPose(Pose2d estimatedRobotPose)
    {
        var rand =
                StateSpaceUtil.makeWhiteNoiseVector(VecBuilder.fill(0.5, 0.5, Units.degreesToRadians(30)));
        return new Pose2d(
                estimatedRobotPose.getX() + rand.get(0, 0),
                estimatedRobotPose.getY() + rand.get(1, 0),
                estimatedRobotPose.getRotation().plus(new Rotation2d(rand.get(2, 0))));
    }
}
