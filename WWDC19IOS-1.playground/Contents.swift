import PlaygroundSupport
import AVFoundation
import UIKit
import CoreML
import Vision




class MainView : UIViewController,  AVCapturePhotoCaptureDelegate {
    private var _session: AVCaptureSession?
    
    private var _input : AVCaptureInput?
    
    private var _imageOut: AVCapturePhotoOutput?
    
    private var _frontCamera: AVCaptureDevice?
    
    private var _previewView  : UIView?
    
    private var _previewLayer : AVCaptureVideoPreviewLayer?
    
    
    private var model : MLModel?
    
    public override func loadView() {
        
        _previewView = UIView()
        guard let view = _previewView else{
            print("Could not initialize view")
            return
        }
        
        view.backgroundColor = UIColor.white
        self.view = view
        
        
        
        
        
    }
    
    
    public override func viewWillAppear(_ animated: Bool) {
        
        do {
            
            
            let compiledModelUrl = try MLModel.compileModel(at: Bundle.main.url(forResource: "TireClassifier", withExtension: "mlmodel")!)
            
            model = try! MLModel(contentsOf: compiledModelUrl)
            
            
            
        } catch {
            print(error.localizedDescription)
        }
        
        super.viewWillAppear(animated)
        _session = AVCaptureSession()
        
        guard let session = _session else{
            print( "An error occurred while initiating the AV Capture Session!")
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset  = .photo
        
        _frontCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        guard let frontCamera = _frontCamera
            else {
                print( "Cannot start front camera!")
                return
        }
        
        do{
            _input = try AVCaptureDeviceInput(device: frontCamera)
        } catch let err as NSError {
            print( err.localizedDescription)
            return
        }
        
        
        guard let input = _input else {
            print( "Cannot start  input!")
            return
        }
        
        session.addInput(input)
        
        
        _imageOut = AVCapturePhotoOutput()
        
        guard let imageOut = _imageOut else{
            print("An error ocurred!")
            return
        }
        
        
        
        
        session.addOutput(imageOut)
        
        
        
        session.commitConfiguration()
        
        _previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        guard let previewLayer  = _previewLayer else{
            print("Cannot config preview layer")
            return
        }
        
        
        self.view.layer.addSublayer(previewLayer)
        previewLayer.frame = self.view.frame
        
        
        
        
        
        
        
        
        
        
        session.startRunning()
        _imageOut =   imageOut
        
        
        print(imageOut)
        

    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
        
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let previewLayer = _previewLayer else {
            print("cannot initilaize")
            return
        }
        
        previewLayer.bounds = self.view.bounds
        previewLayer.frame = self.view.frame
        
        /*let image  = UIImageView(image: UIImage(named: "tire.png"))
         image.frame = CGRect(x: 0, y: self.view.frame.height - 200 , width: self.view.frame.width, height: 200)
         view.addSubview(image)*/
        
        let but = UIButton(frame: CGRect(x: 0, y: self.view.frame.height - 200 , width: self.view.frame.width, height: 200))
        but.setImage( UIImage(named: "tire.png"), for: .normal)
        
        but.addTarget(self, action: #selector(analyze), for: .touchUpInside)
        view.addSubview(but)
        
        
        
    }
    
    
    @objc func analyze(){
        
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        _imageOut!.capturePhoto(with: settings, delegate: self)
        
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: model!) else { return }
        
        
        let request = VNCoreMLRequest(model: model) { (data, error) in do {

            guard let results = data.results as? [VNClassificationObservation] else { return }
            // Assigns the first result (if it exists) to firstObject
            guard let firstObject = results.first else { return }
            
            
            if firstObject.confidence * 100 >= 50 {
                
                
                let alertController = UIAlertController(title: "Good Tire", message: "Your tire looks good to me! please make sure to go to a specialist to take a look!", preferredStyle: .alert)
                
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                
            }else{
                
                let alertController = UIAlertController(title: "Bad Tire", message: "Your tire does not look that great, please make sure to go to a specialist to take a look!", preferredStyle: .alert)
                
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
            }
            
            
            
            }
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        
        
    }
    
    
    
    
    
}






PlaygroundPage.current.liveView = MainView()
