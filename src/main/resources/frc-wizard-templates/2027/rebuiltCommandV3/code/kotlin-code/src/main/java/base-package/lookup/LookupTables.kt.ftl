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
package [=data.basePackage].lookup

import org.wpilib.units.Units.Value

import org.wpilib.math.interpolation.Interpolator
import org.wpilib.math.interpolation.InverseInterpolator
import org.wpilib.units.Measure
import org.wpilib.units.measure.Dimensionless

// WPILib's unit type is aliased so it does not hide Kotlin's own `Unit` type.
import org.wpilib.units.Unit as MeasureUnit

/** Utility object for working with unit-based interpolating tree maps. */
object LookupTables
{
    /**
     * Creates an interpolator operating on Measure objects.
     *
     * @param U The type of the unit for the measure
     * @param M The type of the measure
     * @return The interpolator for the measure
     */
    @Suppress("UNCHECKED_CAST")
    fun <U : MeasureUnit, M : Measure<U>> unitInterpolator(): Interpolator<M>
    {
        return Interpolator { startValue, endValue, t ->
            endValue.minus(startValue).times(t.coerceIn(0.0, 1.0)).plus(startValue) as M
        }
    }

    /**
     * Creates an inverse interpolator operating on Measure objects.
     *
     * @param U The type of the unit for the measure
     * @param M The type of the measure
     * @return The inverse interpolator for the measure
     */
    fun <U : MeasureUnit, M : Measure<U>> inverseUnitInterpolator(): InverseInterpolator<M>
    {
        return InverseInterpolator { startValue, endValue, q ->
            val totalRange: Measure<U> = endValue.minus(startValue)
            if (totalRange.baseUnitMagnitude() <= 0)
            {
                return@InverseInterpolator 0.0
            }

            val queryToStart: Measure<U> = q.minus(startValue)
            if (queryToStart.baseUnitMagnitude() <= 0)
            {
                return@InverseInterpolator 0.0
            }

            (queryToStart.div(totalRange) as Dimensionless).`in`(Value)
        }
    }
}
