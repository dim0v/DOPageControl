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
public class PageControl: UIControl {

    /**
     The number of pages the receiver shows (as dots).
    
     The value of the property is the number of pages for the page control to show as dots. The default value is 0.
    */
    @IBInspectable public var numberOfPages: UInt = 0 {
        didSet {
            indicatorsLayers = nil
            setNeedsLayout()
        }
    }
    
    /**
    The current page, shown by the receiver as a white dot.
    
    The property value is an integer specifying the current page shown minus one; thus a value of zero (the default) indicates the first page. A page control shows the current page as a dot with a bar below it. Values outside the possible range are pinned to either 0 or numberOfPages minus 1.
    */
    @IBInspectable public var currentPage: UInt = 0 {
        didSet {
            placeAndPaintSelectionBar()
            
            if currentPage != oldValue {
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
                indicator.fillColor = colorForIndicatorAtIndex(UInt(idx)).CGColor
            }
            placeAndPaintSelectionBar()
        }
    }
    
    /**
    Sets currentPage property with optional animation
    
    :param: currentPage new currentPage
    :param: animated    should animate
    */
    public func setCurrentPage(currentPage:UInt, animated:Bool) {
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
        
        let offset = CGPoint(x: (bounds.width - intrinsicContentSize().width) / 2, y: (bounds.height - intrinsicContentSize().height) / 2)
        
        for (idx, indicator) in enumerate(indicatorsLayers) {
            let x = offset.x + CGFloat(idx) * (indicatorSize.width + spacing) + indicatorSize.width / 2
            let y = offset.y + indicatorSize.height / 2
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
    
    private func placeAndPaintSelectionBar() {
        selectionBarLayer.position.x = indicatorsLayers[Int(currentPage)].position.x
        selectionBarLayer.position.y = indicatorsLayers[Int(currentPage)].position.y + indicatorSize.height / 2 + 5
        
        selectionBarLayer.fillColor = colorForIndicatorAtIndex(currentPage).CGColor
    }
    
    private func colorForIndicatorAtIndex(index:UInt) -> UIColor {
        if let colors = colorMapping {
            return colors[Int(index)]
        }
        return tintColor
    }
    
    private var indicatorsLayers: [CAShapeLayer]! {
        get {
            if _indicatorsLayers == nil {
                var newLayers = [CAShapeLayer]()
                for idx in 0 ... numberOfPages - 1 {
                    let indicatorLayer = layerForIndicatorWithColor(colorForIndicatorAtIndex(idx))
                    
                    newLayers.append(indicatorLayer)
                    self.layer.addSublayer(indicatorLayer)
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
