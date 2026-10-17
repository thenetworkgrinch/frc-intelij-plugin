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
package [=data.basePackage].mechanisms

import org.wpilib.epilogue.Logged
import org.wpilib.units.Units.Degrees
import org.wpilib.units.Units.Meters
import org.wpilib.units.Units.RPM

import org.wpilib.command3.Command
import org.wpilib.command3.Mechanism
import [=data.basePackage].lookup.LookupTables
import org.wpilib.math.interpolation.InterpolatingTreeMap
import org.wpilib.units.measure.Angle
import org.wpilib.units.measure.AngularVelocity
import org.wpilib.units.measure.Distance

/** Creates a new shooter mechanism object. Only one shooter mechanism should exist at a time. */
@Logged
class Shooter : Mechanism
{
    companion object
    {
        private val HOOD_LUT = InterpolatingTreeMap<Distance, Angle>(
            LookupTables.inverseUnitInterpolator(), LookupTables.unitInterpolator())
        private val FLYWHEEL_LUT = InterpolatingTreeMap<Distance, AngularVelocity>(
            LookupTables.inverseUnitInterpolator(), LookupTables.unitInterpolator())

        init
        {
            // Populate the lookup tables
            HOOD_LUT.put(Meters.of(0.0), Degrees.of(0.0))
            HOOD_LUT.put(Meters.of(1.0), Degrees.of(5.0))
            HOOD_LUT.put(Meters.of(2.0), Degrees.of(10.0))
            HOOD_LUT.put(Meters.of(3.0), Degrees.of(20.0))
            HOOD_LUT.put(Meters.of(4.0), Degrees.of(30.0))

            FLYWHEEL_LUT.put(Meters.of(0.0), RPM.of(1000.0))
            FLYWHEEL_LUT.put(Meters.of(1.0), RPM.of(1000.0))
            FLYWHEEL_LUT.put(Meters.of(2.0), RPM.of(2000.0))
            FLYWHEEL_LUT.put(Meters.of(3.0), RPM.of(3000.0))
            FLYWHEEL_LUT.put(Meters.of(4.0), RPM.of(4000.0))
        }
    }

    private val hood = ShooterHood()
    private val flywheel = ShooterFlywheel()

    init
    {
        setDefaultCommand(idle())
    }

    override fun idle(): Command
    {
        return run { coroutine ->
            coroutine.awaitAll(hood.idle(), flywheel.idle())
        }
            .named("Shooter.Idle")
    }

    /**
     * Shoots at the hub. The flywheel and hood are automatically adjusted based on the distance to
     * the center of the hub. This could potentially be used for passing as well; but, because the
     * center of the hub is six feet above the ground, the distance would need to be fudged to account
     * for the height difference.
     *
     * @param targetDistance The distance to the target, measured from the center of the robot to the
     *     center of the target.
     * @return A command that shoots at the hub
     */
    fun shootAtHub(targetDistance: () -> Distance): Command
    {
        // Because this command is used when only the distance is known,
        // we need to do a little bit of work to convert from a target distance to
        // individual hood angle and flywheel speed values.
        val hoodAngle: () -> Angle = { HOOD_LUT.get(targetDistance()) }
        val flywheelSpeed: () -> AngularVelocity = { FLYWHEEL_LUT.get(targetDistance()) }

        return run { coroutine ->
            coroutine.awaitAll(
                hood.runHoodAngle(hoodAngle), flywheel.runFlywheelSpeed(flywheelSpeed))
        }
            .named("Shooter.ShootAtHub")
    }
}
