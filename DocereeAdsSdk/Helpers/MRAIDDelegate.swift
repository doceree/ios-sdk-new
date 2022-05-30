import Foundation

public protocol MRAIDDelegate {
    func open(_ url: String)
    func close()
    func expand(_ url: String?)
    func resize(to: ResizeProperties)
    
    // AB specific
    func reportDOMSize(_ args: String?)
    func webViewLoaded()
    //func addCloseButton(to:UIView, action:Selector)
}
