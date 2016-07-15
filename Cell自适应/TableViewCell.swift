//
//  TableViewCell.swift
//  Cell自适应
//
//  Created by 刘浩浩 on 16/7/14.
//  Copyright © 2016年 CodingFire. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    var cellImageView = UIImageView()
    var cellLabel = UILabel()
    
    
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Default, reuseIdentifier: nil)
    }
    
    init(style: UITableViewCellStyle, reuseIdentifier: String? ,model:DataModel) {
        super.init(style: .Default, reuseIdentifier: "cell")

        if model.text == nil {
            let size = self.getImageSize(PIC + model.url!)
            cellImageView.removeFromSuperview()
            cellImageView.contentMode = .ScaleAspectFill
            self.addSubview(cellImageView)
            cellImageView.snp_makeConstraints {(make) in
                make.left.equalTo(self.snp_left).offset(10)
                make.top.equalTo(self.snp_top).offset(10)
                make.right.equalTo(self.snp_right).offset(-10)
                make.height.equalTo(cellImageView.snp_width).multipliedBy(size.height / size.width)
            }
        }
        else
        {
            cellLabel.removeFromSuperview()
            cellLabel.numberOfLines = 0
            cellLabel.textColor = UIColor.blackColor()
            cellLabel.font = UIFont.systemFontOfSize(13)
            self.addSubview(cellLabel)
            cellLabel.snp_makeConstraints {(make) in
                make.left.equalTo(self.snp_left).offset(10)
                make.right.equalTo(self.snp_right).offset(-10)
                make.top.equalTo(self.snp_top).offset(10)
                make.bottom.equalTo(self.snp_bottom).offset(0)
            }

        }
    }
    
    func setCellSubViews(model:DataModel,size:CGSize) {
        if model.text == nil {
            cellImageView.sd_setImageWithURL(NSURL(string: PIC + model.url!))
            
        }
        else
        {
            cellLabel.text = model.text!
        }
    }
    
    func cellRowHeight(model:DataModel,size:CGSize) -> CGFloat{
        
        

        if model.text == nil {

            var width:CGFloat
            if UIDevice.currentDevice().orientation == .Portrait  {
                width = WIDTH
            }
            else
            {
                width = HEIGHT
            }
            return size.height / (size.width / width) + 20

        }
        else
        {
            let attribute = [NSFontAttributeName:UIFont.systemFontOfSize(13)]
            let options = NSStringDrawingOptions.UsesLineFragmentOrigin
            
            let size1 = model.text!.boundingRectWithSize(CGSizeMake(WIDTH - 20, 1000), options: options, attributes: attribute, context: nil)
            return size1.height  + 20
        }
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
