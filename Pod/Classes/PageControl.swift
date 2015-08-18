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
public class PageControl: UIControl, UIScrollViewDelegate {

    /**
     The number of pages the receiver shows (as dots).
    
     The value of the property is the number of pages for the page control to show as dots. The default value is 0.
    */
    @IBInspectable public var numberOfPages: Int = 0 {
        didSet {
            indicatorsLayers = nil
            setNeedsLayout()
        }
    }
    
    /**
    The current page, shown by the receiver as a white dot.
    
    The property value is an integer specifying the current page shown minus one; thus a value of zero (the default) indicates the first page. A page control shows the current page as a dot with a bar below it. Values outside the possible range are pinned to either 0 or numberOfPages minus 1.
    */
    @IBInspectable public var currentPage: Int = 0 {
        didSet {
            placeAndPaintSelectionBar()
            
            if currentPage >= numberOfPages {
                currentPage = numberOfPages - 1
            } else if currentPage < 0 {
                currentPage = 0
            } else if currentPage != oldValue {
                sendActionsForControlEvents(UIControlEvents.ValueChanged)
            }
        }
    }
    
    /**
    The size of the page indicators.
    
    A page control shows page indicators as ovals wih the size of this property. Animatable.
    */
    @IBInspectable public var indicatorSize: CGSize = CGSize(width: 8, height: 8) {
        didSet {
            for (idx, indicator) in enumerate(indicatorsLayers) {
                updateSizeForIndicatorLayer(indicator)
            }
            updateSelectionBarSize()
            
            setNeedsLayout()
        }
    }
    
    /// The spacing between page indicators.
    @IBInspectable public var spacing: CGFloat = 8 {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// The duration of the animation of current page switching.
    @IBInspectable public var animationDuration: CGFloat = 0.4
    
    /**
    Colors of page indicators. If set to nil then all indicators will pe painted with the tint color.
    */
    public var colorMapping: [UIColor]? = nil {
        willSet {
            if let val = newValue {
                assert(val.count == Int(numberOfPages), "Color mapping array should contain `numberOfPages` elements")
            }
        }
        didSet {
            for (idx, indicator) in enumerate(indicatorsLayers) {
                indicator.fillColor = colorForIndicatorAtIndex(idx).CGColor
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
    @IBOutlet public var pairedScrollView: UIScrollView? {
        didSet {
            pairedScrollView?.delegate = self
        }
    }
    
    /**
    Sets currentPage property with optional animation
    
    :param: currentPage new currentPage
    :param: animated    should animate
    */
    public func setCurrentPage(currentPage:Int, animated:Bool) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(CFTimeInterval(animated ? animationDuration : 0.0))
        
        self.currentPage = currentPage
        
        CATransaction.commit()
    }
    
    /**
    Lays out subviews
    */
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        for (idx, indicator) in enumerate(indicatorsLayers) {
            let x = layoutOffset.x + CGFloat(idx) * (indicatorSize.width + spacing) + indicatorSize.width / 2
            let y = layoutOffset.y + indicatorSize.height / 2
            indicator.position = CGPoint(x: x, y: y);
        }
        
        updateSelectionBarSize()
        placeAndPaintSelectionBar()
    }
    
    /**
    Returns the natural size for the receiving view, considering only properties of the view itself.
    
    :returns: A size indicating the natural size for the receiving view based on its intrinsic properties.
    */
    public override func intrinsicContentSize() -> CGSize {
        if numberOfPages == 0 {
            return CGSizeZero
        }
        
        let width = indicatorSize.width * CGFloat(numberOfPages) + spacing * CGFloat(numberOfPages - 1)
        return CGSize (width: width, height: indicatorSize.height + 6)
    }
    
    /**
    Tells the delegate that the scroll view has ended decelerating the scrolling movement.
    
    :param: scrollView The scroll-view object that is decelerating the scrolling of the content view.
    */
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        setCurrentPage(Int(scrollView.contentOffset.x / scrollView.bounds.size.width), animated: true)
    }
    
    /**
    Tells the delegate when the user scrolls the content view within the receiver.
    
    :param: scrollView The scroll-view object in which the scrolling occurred.
    */
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        let relativeOffset = scrollView.contentOffset.x / scrollView.bounds.size.width
        
        selectionBarLayer.position = selectionBarPositionForRelativeOffset(relativeOffset)
        
        selectionBarLayer.fillColor = selectionBarColorForRelativeOffset(relativeOffset).CGColor
    }
    
    private var layoutOffset: CGPoint {
        get {
            return CGPoint(x: (bounds.width - intrinsicContentSize().width) / 2, y: (bounds.height - intrinsicContentSize().height) / 2)
        }
    }
    
    private func selectionBarPositionForRelativeOffset(offset: CGFloat) -> CGPoint {
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
    
    private func mixColors(colors:(UIColor, UIColor), proportionOfFirstColor:CGFloat) -> UIColor {
        let proportions = (proportionOfFirstColor, 1 - proportionOfFirstColor)
        
        func mixScalarVals(vals:(CGFloat, CGFloat)) -> CGFloat {
            return proportions.0 * vals.0 + proportions.1 * vals.1;
        }
        
        func mixHueVals(var vals:(CGFloat, CGFloat)) -> CGFloat {
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
    
    private func selectionBarColorForRelativeOffset(offset: CGFloat) -> UIColor {
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
    
    private func placeAndPaintSelectionBar() {
        selectionBarLayer.position = selectionBarPositionForRelativeOffset(CGFloat(currentPage))
        
        selectionBarLayer.fillColor = selectionBarColorForRelativeOffset(CGFloat(currentPage)).CGColor
    }
    
    private func colorForIndicatorAtIndex(index:Int) -> UIColor {
        if let colors = colorMapping {
            return colors[Int(index)]
        }
        return tintColor
    }
    
    private var indicatorsLayers: [CAShapeLayer]! {
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
    
    private func layerForIndicatorWithColor(color:UIColor) -> CAShapeLayer {
        let ret = CAShapeLayer()
        
        ret.fillColor = color.CGColor
        ret.strokeColor = UIColor.clearColor().CGColor
        
        updateSizeForIndicatorLayer(ret)
        
        return ret
    }
    
    private func updateSizeForIndicatorLayer(layer:CAShapeLayer) {
        layer.bounds = CGRect(origin: CGPointZero, size: indicatorSize)
        layer.path = UIBezierPath(ovalInRect: layer.bounds).CGPath
    }
    
    private func updateSelectionBarSize() {
        selectionBarLayer.bounds = CGRect(origin: CGPointZero, size: CGSize(width: indicatorSize.width, height: 2))
        selectionBarLayer.path = UIBezierPath(rect: selectionBarLayer.bounds).CGPath
    }
    
    private var selectionBarLayer: CAShapeLayer! {
        get {
            if _selectionBarLayer == nil {
                _selectionBarLayer = CAShapeLayer()
                _selectionBarLayer!.strokeColor = UIColor.clearColor().CGColor
                
                updateSelectionBarSize()
                
                self.layer.addSublayer(_selectionBarLayer)
            }
            return _selectionBarLayer
        }
        set {
            _selectionBarLayer = newValue
        }
    }
    
    private var _selectionBarLayer: CAShapeLayer? {
        didSet {
            oldValue?.removeFromSuperlayer()
        }
    }
    
    private var _indicatorsLayers: [CAShapeLayer]? {
        didSet {
            if let old = oldValue {
                for indicator in old {
                    indicator.removeFromSuperlayer()
                }
            }
        }
    }
}
