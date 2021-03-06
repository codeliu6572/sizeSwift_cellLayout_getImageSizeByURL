//
//  ViewController.swift
//  Cell自适应
//
//  Created by 刘浩浩 on 16/7/13.
//  Copyright © 2016年 CodingFire. All rights reserved.
//

import UIKit
import SnapKit
var WIDTH = UIScreen.mainScreen().bounds.size.width

var HEIGHT = UIScreen.mainScreen().bounds.size.height

let PIC = "http://pic.108tian.com/pic/"



class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    var _dataArray = NSMutableArray()
    var _sizeArray = [CGSize]()
    
    var _tableView = UITableView()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.changeStatubar), name: UIApplicationWillChangeStatusBarFrameNotification, object: nil)
        
        // Do any additional setup after loading the view, typically from a nib.
        self.loadData()
        
    }
    func changeStatubar() {
        print("width:" + "\(WIDTH)")
        print("height:" +  "\(HEIGHT)")
    }



    func loadData()  {
        //请求URL
        let url:NSURL! = NSURL(string: "https://api.108tian.com/mobile/v3/SceneDetail?id=528b91c9baf6773975578c5c")
        let request:NSMutableURLRequest = NSMutableURLRequest(URL: url)
        let list  = NSMutableArray()
        var paramDic = [String: String]()
        
        if paramDic.count > 0 {
            //设置为GET请求
            request.HTTPMethod = "GET"
            //拆分字典,subDic是其中一项，将key与value变成字符串
            for subDic in paramDic {
                let tmpStr = "\(subDic.0)=\(subDic.1)"
                list.addObject(tmpStr)
            }
            //用&拼接变成字符串的字典各项
            let paramStr = list.componentsJoinedByString("&")
            //UTF8转码，防止汉字符号引起的非法网址
            let paraData = paramStr.dataUsingEncoding(NSUTF8StringEncoding)
            //设置请求体
            request.HTTPBody = paraData
        }
        //默认session配置
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        //发起请求
        let dataTask = session.dataTaskWithRequest(request) { (data, response, error) in
            
            //            let str:String! = String(data: data!, encoding: NSUTF8StringEncoding)
            //            print("str:\(str)")
            //转Json
            let jsonData:NSDictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
            print(jsonData)
            
            let data = jsonData["data"] as! NSDictionary
            let details = data["details"] as! NSDictionary
            let paragraph = details["paragraph"] as! NSArray
            
            for subDic in paragraph {
                let body = subDic["body"] as! NSArray
                for bodySubDic in body{
                    let dataModel = DataModel()
                    var size:CGSize
                    if bodySubDic.objectForKey("text") != nil {
                        dataModel.text = bodySubDic["text"] as? String
                        size = CGSizeZero
                    }
                    else
                    {
                        dataModel.url = (bodySubDic["img"])!!["url"] as? String
                        size = self.getImageSize(PIC + ((bodySubDic["img"])!!["url"] as? String)!)
                    }
                    
                    self._dataArray.addObject(dataModel)
                    self._sizeArray.append(size)
                    
                }
                
                
            }
            dispatch_async(dispatch_get_main_queue(), {
                print("OK")
                self.creatTableView()
                self._tableView.reloadData()

            })
          

            

        }
        //请求开始
        dataTask.resume()


    }
    
    

    
    func creatTableView() {

        _tableView = UITableView(frame: CGRectMake(0, 0, WIDTH, HEIGHT), style: .Plain)
        _tableView.delegate = self
        _tableView.dataSource = self
        self.view.addSubview(_tableView)
        _tableView.snp_makeConstraints {(make) in
            make.left.top.right.bottom.equalTo(self.view).offset(0)
        }

    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _dataArray.count
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        
        let size = _sizeArray[indexPath.row] as! CGSize
        let dataModel = _dataArray[indexPath.row] as! DataModel
        let myCell = TableViewCell(style: .Default, reuseIdentifier: nil)
        return myCell.cellRowHeight(dataModel, size: size)

        

    }
   
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let dataModel = _dataArray[indexPath.row] as! DataModel
        let size = _sizeArray[indexPath.row] as! CGSize
        let myCell = TableViewCell(style: .Default, reuseIdentifier: "cell", model: dataModel)
        myCell.setCellSubViews(dataModel, size: size)
        return myCell

        
    }
    func getImageSize(imageURL:String) ->CGSize {
        var URL:NSURL?
        if imageURL.isKindOfClass(NSString) {
            URL = NSURL(string: imageURL)
        }
        if URL == nil
        {
            return  CGSizeZero             // url不正确
        }
        let request = NSMutableURLRequest(URL: URL!)
        let pathExtendsion = URL?.pathExtension?.lowercaseString
        
        var size = CGSizeZero
        if pathExtendsion == "png" {
            size = self.getPNGImageSize(request)
        }
        else if pathExtendsion == "gif"
        {
            size = self.getGIFImageSize(request)
        }
        else{
            size = self.getJPGImageSize(request)
        }
        if CGSizeEqualToSize(CGSizeZero, size)                   // 如果获取文件头信息失败,发送异步请求请求原图
        {
            
            guard let data = try? NSURLConnection.sendSynchronousRequest(request, returningResponse: nil) else{
                return size
            }
            let image = UIImage(data: data)
            if image != nil {
                size = (image?.size)!
            }
            
        }
        return size
        
    }
    func getPNGImageSize(request:NSMutableURLRequest) -> CGSize {
        //  获取PNG图片的大小
        request.setValue("bytes=16-23", forHTTPHeaderField: "Range")
        guard let data = try? NSURLConnection.sendSynchronousRequest(request, returningResponse: nil) else{
            return CGSizeZero
        }
        if data.length == 8 {
            var w1:Int = 0
            var w2:Int = 0
            var w3:Int = 0
            var w4:Int = 0
            data.getBytes(&w1, range: NSMakeRange(0, 1))
            data.getBytes(&w2, range: NSMakeRange(1, 1))
            data.getBytes(&w3, range: NSMakeRange(2, 1))
            data.getBytes(&w4, range: NSMakeRange(3, 1))
            
            let w = (w1 << 24) + (w2 << 16) + (w3 << 8) + w4
            var h1:Int = 0
            var h2:Int = 0
            var h3:Int = 0
            var h4:Int = 0
            data.getBytes(&h1, range: NSMakeRange(4, 1))
            data.getBytes(&h2, range: NSMakeRange(5, 1))
            data.getBytes(&h3, range: NSMakeRange(6, 1))
            data.getBytes(&h4, range: NSMakeRange(7, 1))
            let h = (h1 << 24) + (h2 << 16) + (h3 << 8) + h4
            
            return CGSizeMake(CGFloat(w), CGFloat(h));
            
        }
        
        return CGSizeZero;
        
    }
    
    func getGIFImageSize(request:NSMutableURLRequest) -> CGSize {
        //  获取GIF图片的大小
        request.setValue("bytes=6-9", forHTTPHeaderField: "Range")
        guard var data = try? NSURLConnection.sendSynchronousRequest(request, returningResponse: nil) else{
            return CGSizeZero
        }
        if data.length == 4 {
            var w1:Int = 0
            var w2:Int = 0
            
            data.getBytes(&w1, range: NSMakeRange(0, 1))
            data.getBytes(&w2, range: NSMakeRange(1, 1))
            
            var w = w1 + (w2 << 8)
            var h1:Int = 0
            var h2:Int = 0
            
            data.getBytes(&h1, range: NSMakeRange(2, 1))
            data.getBytes(&h2, range: NSMakeRange(3, 1))
            var h = h1 + (h2 << 8)
            
            return CGSizeMake(CGFloat(w), CGFloat(h));
            
        }
        
        return CGSizeZero;
    }
    
    func getJPGImageSize(request:NSMutableURLRequest) -> CGSize {
        //  获取JPG图片的大小
        request.setValue("bytes=0-209", forHTTPHeaderField: "Range")
        guard var data = try? NSURLConnection.sendSynchronousRequest(request, returningResponse: nil) else{
            return CGSizeZero
        }
        if data.length <= 0x58 {
            return CGSizeZero
            
        }
        if data.length < 210 {
            var w1:Int = 0
            var w2:Int = 0
            
            data.getBytes(&w1, range: NSMakeRange(0x60, 0x1))
            data.getBytes(&w2, range: NSMakeRange(0x61, 0x1))
            
            var w = (w1 << 8) + w2
            var h1:Int = 0
            var h2:Int = 0
            
            data.getBytes(&h1, range: NSMakeRange(0x5e, 0x1))
            data.getBytes(&h2, range: NSMakeRange(0x5f, 0x1))
            var h = (h1 << 8) + h2
            
            return CGSizeMake(CGFloat(w), CGFloat(h));
            
        }
        else
        {
            var word = 0x0
            data.getBytes(&word, range: NSMakeRange(0x15, 0x1))
            if word == 0xdb {
                data.getBytes(&word, range: NSMakeRange(0x5a, 0x1))
                if word == 0xdb {
                    var w1:Int = 0
                    var w2:Int = 0
                    
                    data.getBytes(&w1, range: NSMakeRange(0xa5, 0x1))
                    data.getBytes(&w2, range: NSMakeRange(0xa6, 0x1))
                    
                    var w = (w1 << 8) + w2
                    var h1:Int = 0
                    var h2:Int = 0
                    
                    data.getBytes(&h1, range: NSMakeRange(0xa3, 0x1))
                    data.getBytes(&h2, range: NSMakeRange(0xa4, 0x1))
                    var h = (h1 << 8) + h2
                    
                    return CGSizeMake(CGFloat(w), CGFloat(h));
                    
                }
                else
                {
                    var w1:Int = 0
                    var w2:Int = 0
                    
                    data.getBytes(&w1, range: NSMakeRange(0x60, 0x1))
                    data.getBytes(&w2, range: NSMakeRange(0x61, 0x1))
                    
                    var w = (w1 << 8) + w2
                    var h1:Int = 0
                    var h2:Int = 0
                    
                    data.getBytes(&h1, range: NSMakeRange(0x5e, 0x1))
                    data.getBytes(&h2, range: NSMakeRange(0x5f, 0x1))
                    var h = (h1 << 8) + h2
                    
                    return CGSizeMake(CGFloat(w), CGFloat(h));
                }
            }
            else {
                return CGSizeZero;
            }
        }
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

