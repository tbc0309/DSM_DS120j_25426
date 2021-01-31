<?php

/**
 * PHPExcel_Style_Color
 *
 * Copyright (c) 2006 - 2015 PHPExcel
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * @category   PHPExcel
 * @package    PHPExcel_Style
 * @copyright Copyright (c) 2006 - 2015 PHPExcel (http://www.codeplex.com/PHPExcel)
 * @license http://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt    LGPL
 * @version ##VERSION##, ##DATE##
 */
class PHPExcel_Style_Color extends PHPExcel_Style_Supervisor implements PHPExcel_IComparable
{
    /* Colors */
    const COLOR_BLACK      = 'FF000000';
    const COLOR_WHITE      = 'FFFFFFFF';
    const COLOR_RED        = 'FFFF0000';
    const COLOR_DARKRED    = 'FF800000';
    const COLOR_BLUE       = 'FF0000FF';
    const COLOR_DARKBLUE   = 'FF000080';
    const COLOR_GREEN      = 'FF00FF00';
    const COLOR_DARKGREEN  = 'FF008000';
    const COLOR_YELLOW     = 'FFFFFF00';
    const COLOR_DARKYELLOW = 'FF808000';

    /**
     * Indexed colors array
     *
     * @var array
     */
    protected static $indexedColors;

    /**
     * ARGB - Alpha RGB
     *
     * @var string
     */
    protected $argb = null;

    /**
     * Parent property name
     *
     * @var string
     */
    protected $parentPropertyName;


    /**
     * Create a new PHPExcel_Style_Color
     *
     * @param    string    $pARGB            ARGB value for the colour
     * @param    boolean    $isSupervisor    Flag indicating if this is a supervisor or not
     *                                    Leave this value at default unless you understand exactly what
     *                                        its ramifications are
     * @param    boolean    $isConditional    Flag indicating if this is a conditional style or not
     *                                    Leave this value at default unless you understand exactly what
     *                                        its ramifications are
     */
    public function __construct($pARGB = PHPExcel_Style_Color::COLOR_BLACK, $isSupervisor = false, $isConditional = false)
    {
        //    Supervisor?
        parent::__construct($isSupervisor);

        //    Initialise values
        if (!$isConditional) {
            $this->argb = $pARGB;
        }
    }

    /**
     * Bind parent. Only used for supervisor
     *
     * @param mixed $parent
     * @param string $parentPropertyName
     * @return PHPExcel_Style_Color
     */
    public function bindParent($parent, $parentPropertyName = null)
    {
        $this->parent = $parent;
        $this->parentPropertyName = $parentPropertyName;
        return $this;
    }

    /**
     * Get the shared style component for the currently active cell in currently active sheet.
     * Only used for style supervisor
     *
     * @return PHPExcel_Style_Color
     */
    public function getSharedComponent()
    {
        switch ($this->parentPropertyName) {
            case 'endColor':
                return $this->parent->getSharedComponent()->getEndColor();
            case 'color':
                return $this->parent->getSharedComponent()->getColor();
            case 'startColor':
                return $this->parent->getSharedComponent()->getStartColor();
        }
    }

    /**
     * Build style array from subcomponents
     *
     * @param array $array
     * @return array
     */
    public function getStyleArray($array)
    {
        switch ($this->parentPropertyName) {
            case 'endColor':
                $key = 'endcolor';
                break;
            case 'color':
                $key = 'color';
                break;
            case 'startColor':
                $key = 'startcolor';
                break;

        }
        return $this->parent->getStyleArray(array($key => $array));
    }

    /**
     * Apply styles from array
     *
     * <code>
     * $objPHPExcel->getActiveSheet()->getStyle('B2')->getFont()->getColor()->applyFromArray( array('rgb' => '808080') );
     * </code>
     *
     * @param    array    $pStyles    Array containing style information
     * @throws    PHPExcel_Exception
     * @return PHPExcel_Style_Color
     */
    public function applyFromArray($pStyles = null)
    {
        if (is_array($pStyles)) {
            if ($this->isSupervisor) {
                $this->getActiveSheet()->getStyle($this->getSelectedCells())->applyFromArray($this->getStyleArray($pStyles));
            } else {
                if (array_key_exists('rgb', $pStyles)) {
                    $this->setRGB($pStyles['rgb']);
                }
                if (array_key_exists('argb', $pStyles)) {
                    $this->setARGB($pStyles['argb']);
                }
            }
        } else {
            throw new PHPExcel_Exception("Invalid style array passed.");
        }
        return $this;
    }

    /**
     * Get ARGB
     *
     * @return string
     */
    public function getARGB()
    {
        if ($this->isSupervisor) {
            return $this->getSharedComponent()->getARGB();
        }
        return $this->argb;
    }

    /**
     * Set ARGB
     *
     * @param string $pValue
     * @return PHPExcel_Style_Color
     */
    public function setARGB($pValue = PHPExcel_Style_Color::COLOR_BLACK)
    {
        if ($pValue == '') {
            $pValue = PHPExcel_Style_Color::COLOR_BLACK;
        }
        if ($this->isSupervisor) {
            $styleArray = $this->getStyleArray(array('argb' => $pValue));
            $this->getActiveSheet()->getStyle($this->getSelectedCells())->applyFromArray($styleArray);
        } else {
            $this->argb = $pValue;
        }
        return $this;
    }

    /**
     * Get RGB
     *
     * @return string
     */
    public function getRGB()
    {
        if ($this->isSupervisor) {
            return $this->getSharedComponent()->getRGB();
        }
        return substr($this->argb, 2);
    }

    /**
     * Set RGB
     *
     * @param    string    $pValue    RGB value
     * @return PHPExcel_Style_Color
     */
    public function setRGB($pValue = '000000')
    {
        if ($pValue == '') {
            $pValue = '000000';
        }
        if ($this->isSupervisor) {
            $styleArray = $this->getStyleArray(array('argb' => 'FF' . $pValue));
            $this->getActiveSheet()->getStyle($this->getSelectedCells())->applyFromArray($styleArray);
        } else {
            $this->argb = 'FF' . $pValue;
        }
        return $this;
    }

    /**
     * Get a specified colour component of an RGB value
     *
     * @private
     * @param    string        $RGB        The colour as an RGB value (e.g. FF00CCCC or CCDDEE
     * @param    int            $offset        Position within the RGB value to extract
     * @param    boolean        $hex        Flag indicating whether the component should be returned as a hex or a
     *                                    decimal value
     * @return    string        The extracted colour component
     */
    private static function getColourComponent($RGB, $offset, $hex = true)
    {
        $colour = substr($RGB, $offset, 2);
        if (!$hex) {
            $colour = hexdec($colour);
        }
        return $colour;
    }

    /**
     * Get the red colour component of an RGB value
     *
     * @param    string        $RGB        The colour as an RGB value (e.g. FF00CCCC or CCDDEE
     * @param    boolean        $hex        Flag indicating whether the component should be returned as a hex or a
     *                                    decimal value
     * @return    string        The red colour component
     */
    public static function getRed($RGB, $hex = true)
    {
        return self::getColourComponent($RGB, strlen($RGB) - 6, $hex);
    }

    /**
     * Get the green colour component of an RGB value
     *
     * @param    string        $RGB        The colour as an RGB value (e.g. FF00CCCC or CCDDEE
     * @param    boolean        $hex        Flag indicating whether the component should be returned as a hex or a
     *                                    decimal value
     * @return    string        The green colour component
     */
    public static function getGreen($RGB, $hex = true)
    {
        return self::getColourComponent($RGB, strlen($RGB) - 4, $hex);
    }

    /**
     * Get the blue colour component of an RGB value
     *
     * @param    string        $RGB        The colour as an RGB value (e.g. FF00CCCC or CCDDEE
     * @param    boolean        $hex        Flag indicating whether the component should be returned as a hex or a
     *                                    decimal value
     * @return    string        The blue colour component
     */
    public static function getBlue($RGB, $hex = true)
    {
        return self::getColourComponent($RGB, strlen($RGB) - 2, $hex);
    }

    /**
     * Adjust the brightness of a color
     *
     * @param    string        $hex    The colour as an RGBA or RGB value (e.g. FF00CCCC or CCDDEE)
     * @param    float        $adjustPercentage    The percentage by which to adjust the colour as a float from -1 to 1
     * @return    string        The adjusted colour as an RGBA or RGB value (e.g. FF00CCCC or CCDDEE)
     */
    public static function changeBrightness($hex, $adjustPercentage)
    {
        $rgba = (strlen($hex) == 8);

        $red = self::getRed($hex, false);
        $green = self::getGreen($hex, false);
        $blue = self::getBlue($hex, false);
        if ($adjustPercentage > 0) {
            $red += (255 - $red) * $adjustPercentage;
            $green += (255 - $green) * $adjustPercentage;
            $blue += (255 - $blue) * $adjustPercentage;
        } else {
            $red += $red * $adjustPercentage;
            $green += $green * $adjustPercentage;
            $blue += $blue * $adjustPercentage;
        }

        if ($red < 0) {
            $red = 0;
        } elseif ($red > 255) {
            $red = 255;
        }
        if ($green < 0) {
            $green = 0;
        } elseif ($green > 255) {
            $green = 255;
        }
        if ($blue < 0) {
            $blue = 0;
        } elseif ($blue > 255) {
            $blue = 255;
        }

        $rgb = strtoupper(
            str_pad(dechex($red), 2, '0', 0) .
            str_pad(dechex($green), 2, '0', 0) .
            str_pad(dechex($blue), 2, '0', 0)
        );
        return (($rgba) ? 'FF' : '') . $rgb;
    }

    /**
     * Get indexed color
     *
     * @param    int            $pIndex            Index entry point into the colour array
     * @param    boolean        $background        Flag to indicate whether default background or foreground colour
     *                                            should be returned if the indexed colour doesn't exist
     * @return    PHPExcel_Style_Color
     */
    public static function indexedColor($pIndex, $background = false)
    {
        // Clean parameter
        $pIndex = intval($pIndex);

        // Indexed colors
        if (is_null(self::$indexedColors)) {
            /*** SYNO start ***/
            // make indexedColor correspond with ISO/IEC-29500-1
            self::$indexedColors = array(
                // Default Color Index as per 18.8.27 of ECMA Part 4
                // 64: system foreground, mapping to black
                // 65: system background, mapping to white
                '00000000', '00FFFFFF', '00FF0000', '0000FF00', '000000FF', // 0-4
                '00FFFF00', '00FF00FF', '0000FFFF', '00000000', '00FFFFFF', // 5-9
                '00FF0000', '0000FF00', '000000FF', '00FFFF00', '00FF00FF', // 10-14
                '0000FFFF', '00800000', '00008000', '00000080', '00808000', // 15-19
                '00800080', '00008080', '00C0C0C0', '00808080', '009999FF', // 20-24
                '00993366', '00FFFFCC', '00CCFFFF', '00660066', '00FF8080', // 25-29
                '000066CC', '00CCCCFF', '00000080', '00FF00FF', '00FFFF00', // 30-34
                '0000FFFF', '00800080', '00800000', '00008080', '000000FF', // 35-39
                '0000CCFF', '00CCFFFF', '00CCFFCC', '00FFFF99', '0099CCFF', // 40-44
                '00FF99CC', '00CC99FF', '00FFCC99', '003366FF', '0033CCCC', // 45-49
                '0099CC00', '00FFCC00', '00FF9900', '00FF6600', '00666699', // 50-54
                '00969696', '00003366', '00339966', '00003300', '00333300', // 55-59
                '00993300', '00993366', '00333399', '00333333', '00000000', // 60-64
                '00FFFFFF'                                                  // 65
            );
            /*** SYNO end ***/
        }

        if (array_key_exists($pIndex, self::$indexedColors)) {
            return new PHPExcel_Style_Color(self::$indexedColors[$pIndex]);
        }

        if ($background) {
            return new PHPExcel_Style_Color(self::COLOR_WHITE);
        }
        return new PHPExcel_Style_Color(self::COLOR_BLACK);
    }

    /**
     * Get hash code
     *
     * @return string    Hash code
     */
    public function getHashCode()
    {
        if ($this->isSupervisor) {
            return $this->getSharedComponent()->getHashCode();
        }
        return md5(
            $this->argb .
            __CLASS__
        );
    }

    /***SYNO start***/
    public static function SetIndexedColor($indexedColors)
    {
        self::$indexedColors = $indexedColors;
    }
    /***SYNO end***/

}
