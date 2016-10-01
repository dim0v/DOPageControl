//
//  PageControl.swift
//  Pods
//
//  Created by Dmytro Ovcharenko on 28.07.15.
//
//

import UIKit

/// Provides functionality similar to UIPageControl. Has slightly different visual appearence and allows to customize page indicators size, color and spacing
@IBDesignable
open class PageControl: UIControl, UIScrollViewDelegate {

    /**
     The number of pages the receiver shows (as dots).
    
     The value of the property is the number of pages for the page control to show as dots. The default value is 0.
    */
    @IBInspectable open var numberOfPages: Int = 0 {
        didSet {
            indicatorsLayers = nil
            setNeedsLayout()
        }
    }
    
    /**
    The current page, shown by the receiver as a white dot.
    
    The property value is an integer specifying the current page shown minus one; thus a value of zero (the default) indicates the first page. A page control shows the current page as a dot with a bar below it. Values outside the possible range are pinned to either 0 or numberOfPages minus 1.
    */
    @IBInspectable open var currentPage: Int = 0 {
        didSet {
            placeAndPaintSelectionBar()
            
            if currentPage >= numberOfPages {
                currentPage = numberOfPages - 1
            } else if currentPage < 0 {
                currentPage = 0
            } else if currentPage != oldValue {
                sendActions(for: UIControlEvents.valueChanged)
            }
        }
    }
    
    /**
    The size of the page indicators.
    
    A page control shows page indicators as ovals wih the size of this property. Animatable.
    */
    @IBInspectable open var indicatorSize: CGSize = CGSize(width: 8, height: 8) {
        didSet {
            for (_, indicator) in indicatorsLayers.enumerated() {
                updateSizeForIndicatorLayer(indicator)
            }
            updateSelectionBarSize()
            
            setNeedsLayout()
        }
    }
    
    /// The spacing between page indicators.
    @IBInspectable open var spacing: CGFloat = 8 {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// The duration of the animation of current page switching.
    @IBInspectable open var animationDuration: CGFloat = 0.4
    
    /**
    Colors of page indicators. If set to nil then all indicators will pe painted with the tint color.
    */
    open var colorMapping: [UIColor]? = nil {
        willSet {
            if let val = newValue {
                assert(val.count == Int(numberOfPages), "Color mapping array should contain `numberOfPages` elements")
            }
        }
        didSet {
            for (idx, indicator) in indicatorsLayers.enumerated() {
                indicator.fillColor = colorForIndicatorAtIndex(idx).cgColor
            }
            placeAndPaintSelectionBar()
        }
    }
    
    /**
    An instance of UIScrollView which contains actual pages represented by the receiver.
    
    If this is set than the control will change its state automaticaly during scrolling in that UIScrollView.
    
    :Note: Even though the control will automatically change its state with nice and smooth animations when this property is set, it stills user responsibility to set numberOfPages correctly for the control to work properly.
    :Note: Only horizontally laid out pages are supported.
    
    :Warning: UIScrollView's delegate will be replaced by the receiving PageControl instance!
    */
    @IBOutlet open var pairedScrollView: UIScrollView? {
        didSet {
            pairedScrollView?.delegate = self
        }
    }
    
    /**
    Sets currentPage property with optional animation
    
    - parameter currentPage: new currentPage
    - parameter animated:    should animate
    */
    open func setCurrentPage(_ currentPage:Int, animated:Bool) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(CFTimeInterval(animated ? animationDuration : 0.0))
        
        self.currentPage = currentPage
        
        CATransaction.commit()
    }
    
    /**
    Lays out subviews
    */
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        for (idx, indicator) in indicatorsLayers.enumerated() {
            let x = layoutOffset.x + CGFloat(idx) * (indicatorSize.width + spacing) + indicatorSize.width / 2
            let y = layoutOffset.y + indicatorSize.height / 2
            indicator.position = CGPoint(x: x, y: y);
        }
        
        updateSelectionBarSize()
        placeAndPaintSelectionBar()
    }
    
    /**
    Returns the natural size for the receiving view, considering only properties of the view itself.
    
    - returns: A size indicating the natural size for the receiving view based on its intrinsic properties.
    */
    open override var intrinsicContentSize : CGSize {
        if numberOfPages == 0 {
            return CGSize.zero
        }
        
        let width = indicatorSize.width * CGFloat(numberOfPages) + spacing * CGFloat(numberOfPages - 1)
        return CGSize (width: width, height: indicatorSize.height + 6)
    }
    
    /**
    Tells the delegate that the scroll view has ended decelerating the scrolling movement.
    
    - parameter scrollView: The scroll-view object that is decelerating the scrolling of the content view.
    */
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setCurrentPage(Int(scrollView.contentOffset.x / scrollView.bounds.size.width), animated: true)
    }
    
    /**
    Tells the delegate when the user scrolls the content view within the receiver.
    
    - parameter scrollView: The scroll-view object in which the scrolling occurred.
    */
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var relativeOffset = scrollView.contentOffset.x / scrollView.bounds.size.width
        
        if !relativeOffset.isNormal {
            relativeOffset = 0.0;
        }
        
        selectionBarLayer.position = selectionBarPositionForRelativeOffset(relativeOffset)
        selectionBarLayer.fillColor = selectionBarColorForRelativeOffset(relativeOffset).cgColor
        
        selectionBarLayer.removeAllAnimations() //preventing ease in/out when animating changes
    }
    
    fileprivate var layoutOffset: CGPoint {
        get {
            return CGPoint(x: (bounds.width - intrinsicContentSize.width) / 2, y: (bounds.height - intrinsicContentSize.height) / 2)
        }
    }
    
    fileprivate func selectionBarPositionForRelativeOffset(_ offset: CGFloat) -> CGPoint {
        let (intPart, fractPart) = modf(offset)
        
        if numberOfPages == 0 {
            return layoutOffset
        }
        
        let y = layoutOffset.y + indicatorSize.height + 5
        
        if Int(intPart) >= numberOfPages - 1 {
            return CGPoint(x: indicatorsLayers[numberOfPages - 1].position.x, y: y)
        }
        if Int(intPart) < 0 {
            return CGPoint(x: indicatorsLayers[0].position.x, y: y)
        }
        
        let pos1 = indicatorsLayers[Int(intPart)].position.x
        let pos2 = indicatorsLayers[Int(intPart + 1)].position.x
        
        let x = pos1 * (1 - fractPart) +
                pos2 * fractPart
        
        return CGPoint(x: x, y: y)
    }
    
    fileprivate func mixColors(_ colors:(UIColor, UIColor), proportionOfFirstColor:CGFloat) -> UIColor {
        let proportions = (proportionOfFirstColor, 1 - proportionOfFirstColor)
        
        func mixScalarVals(_ vals:(CGFloat, CGFloat)) -> CGFloat {
            return proportions.0 * vals.0 + proportions.1 * vals.1;
        }
        
        func mixHueVals(_ inputVals:(CGFloat, CGFloat)) -> CGFloat {
            var vals = inputVals;
            
            let shouldChangeDirection = fabs(vals.0 - vals.1) > fabs(min(vals.0, vals.1) - max(vals.0, vals.1) + 1)
            
            if shouldChangeDirection {
                if vals.0 < vals.1 {
                    vals.0 += CGFloat(1)
                } else {
                    vals.1 += CGFloat(1)
                }
            }
            
            return fmod(proportions.0 * vals.0 + proportions.1 * vals.1, 1.0)
        }
        
        var (h1, s1, b1, a1) = (CGFloat(), CGFloat(), CGFloat(), CGFloat())
        
        var (h2, s2, b2, a2) = (CGFloat(), CGFloat(), CGFloat(), CGFloat())
        
        colors.0.getHue(&h1, saturation: &s1, brightness: &b1, alpha: &a1)
        colors.1.getHue(&h2, saturation: &s2, brightness: &b2, alpha: &a2)
        
        let resultingColor = UIColor(
            hue:        mixHueVals((h1, h2)),
            saturation: mixScalarVals((s1, s2)),
            brightness: mixScalarVals((b1, b2)),
            alpha:      mixScalarVals((a1, a2))
        )
        
        return resultingColor
    }
    
    fileprivate func selectionBarColorForRelativeOffset(_ offset: CGFloat) -> UIColor {
        let (intPart, fractPart) = modf(offset)
        
        if Int(intPart) >= numberOfPages - 1 {
            return colorForIndicatorAtIndex(numberOfPages - 1)
        }
        
        if Int(intPart) < 0 {
            return colorForIndicatorAtIndex(0)
        }
        
        let color1 = colorForIndicatorAtIndex(Int(intPart))
        let color2 = colorForIndicatorAtIndex(Int(intPart + 1))
        
        return mixColors((color1, color2), proportionOfFirstColor: 1 - fractPart)
    }
    
    fileprivate func placeAndPaintSelectionBar() {
        selectionBarLayer.position = selectionBarPositionForRelativeOffset(CGFloat(currentPage))
        
        selectionBarLayer.fillColor = selectionBarColorForRelativeOffset(CGFloat(currentPage)).cgColor
    }
    
    fileprivate func colorForIndicatorAtIndex(_ index:Int) -> UIColor {
        if let colors = colorMapping {
            return colors[Int(index)]
        }
        return tintColor
    }
    
    fileprivate var indicatorsLayers: [CAShapeLayer]! {
        get {
            if _indicatorsLayers == nil {
                var newLayers = [CAShapeLayer]()
                
                if numberOfPages > 0 {
                    for idx in 0 ... numberOfPages - 1 {
                        let indicatorLayer = layerForIndicatorWithColor(colorForIndicatorAtIndex(idx))
                        
                        newLayers.append(indicatorLayer)
                        self.layer.addSublayer(indicatorLayer)
                    }
                }
                
                _indicatorsLayers = newLayers
            }
            
            return _indicatorsLayers
        }
        
        set {
            _indicatorsLayers = newValue
        }
    }
    
    fileprivate func layerForIndicatorWithColor(_ color:UIColor) -> CAShapeLayer {
        let ret = CAShapeLayer()
        
        ret.fillColor = color.cgColor
        ret.strokeColor = UIColor.clear.cgColor
        
        updateSizeForIndicatorLayer(ret)
        
        return ret
    }
    
    fileprivate func updateSizeForIndicatorLayer(_ layer:CAShapeLayer) {
        layer.bounds = CGRect(origin: CGPoint.zero, size: indicatorSize)
        layer.path = UIBezierPath(ovalIn: layer.bounds).cgPath
    }
    
    fileprivate func updateSelectionBarSize() {
        selectionBarLayer.bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: indicatorSize.width, height: 2))
        selectionBarLayer.path = UIBezierPath(rect: selectionBarLayer.bounds).cgPath
    }
    
    fileprivate var selectionBarLayer: CAShapeLayer! {
        get {
            if _selectionBarLayer == nil {
                _selectionBarLayer = CAShapeLayer()
                _selectionBarLayer!.strokeColor = UIColor.clear.cgColor
                
                updateSelectionBarSize()
                
                self.layer.addSublayer(_selectionBarLayer!)
            }
            return _selectionBarLayer
        }
        set {
            _selectionBarLayer = newValue
        }
    }
    
    fileprivate var _selectionBarLayer: CAShapeLayer? {
        didSet {
            oldValue?.removeFromSuperlayer()
        }
    }
    
    fileprivate var _indicatorsLayers: [CAShapeLayer]? {
        didSet {
            if let old = oldValue {
                for indicator in old {
                    indicator.removeFromSuperlayer()
                }
            }
        }
    }
}
