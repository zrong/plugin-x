/****************************************************************************
Copyright (c) 2014 cocos2d-x.org

http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/

#import "IAPWrapper.h"
#include "PluginUtilsIOS.h"
#include "ProtocolIAP.h"
#import <StoreKit/StoreKit.h>
#import "ParseUtils.h"

using namespace cocos2d::plugin;

@implementation IAPWrapper

+ (void) onPayResult:(id) obj withRet:(IAPResult) ret withMsg:(NSString*) msg
{
    PluginProtocol* plugin = PluginUtilsIOS::getPluginPtr(obj);
    ProtocolIAP* iapPlugin = dynamic_cast<ProtocolIAP*>(plugin);
    PayResultListener *listener = iapPlugin->getResultListener();
    ProtocolIAP::ProtocolIAPCallback callback = iapPlugin->getCallback();
    const char* chMsg = [msg UTF8String];
    PayResultCode cRet = (PayResultCode) ret;
    //======== zrong 2015-03-22
    // 那个傻 B 写的代码，明明把 listener 废弃了，这里又不判断，那callback 有何用？
    if (iapPlugin) {
        if (listener) {
            iapPlugin->onPayResult(cRet, chMsg);
        }else if(callback){
            std::string stdmsg(chMsg);
            callback(cRet,stdmsg);
        }else {
            PluginUtilsIOS::outputLog("No listener and callback!");
        }
    } else {
        PluginUtilsIOS::outputLog("Can't find the C++ object of the IAP plugin");
    }
}
+(void) onRequestProduct:(id)obj withRet:(ProductRequest) ret withProducts:(NSArray *)products{
    PluginProtocol* plugin = PluginUtilsIOS::getPluginPtr(obj);
    ProtocolIAP* iapPlugin = dynamic_cast<ProtocolIAP*>(plugin);
    PayResultListener *listener = iapPlugin->getResultListener();
    ProtocolIAP:: ProtocolIAPCallback callback = iapPlugin->getCallback();
    if (iapPlugin) {
        if(listener){
            TProductList pdlist;
            if (products) {
                for(SKProduct *product in products){
                    TProductInfo info;
                    info.insert(std::make_pair("productId", std::string([product.productIdentifier UTF8String])));
                    info.insert(std::make_pair("productName", std::string([product.localizedTitle UTF8String])));
                    info.insert(std::make_pair("productPrice", std::string([[product.price stringValue] UTF8String])));
                    info.insert(std::make_pair("productDesc", std::string([product.localizedDescription UTF8String])));
                    pdlist.push_back(info);
                }
            }
            listener->onRequestProductsResult((IAPProductRequest )ret,pdlist);
        }else if(callback){
            // zrong 2015-03-22 START ========
            // the projects cannot convert to json data.
            // will get a error: 'NSInvalidArgumentException', reason: 'Invalid type in JSON write (SKProduct)'
            NSMutableArray *jsonArray = [[NSMutableArray alloc] init];
            for (SKProduct * skp in products) {
                NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      skp.productIdentifier, @"productIdentifier",
                                      skp.localizedTitle, @"localizedTitle",
                                      skp.localizedDescription, @"localizedDescriptiono",
                                      skp.price, @"price",
                                      nil];
                [jsonArray addObject:dict];
            }
            
            NSString *productInfo = nil;
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonArray
                                                               options:0 // Pass 0 if you don't care about the readability of the generated string
                                                                 error:&error];
            if (! jsonData) {
                NSLog(@"Got an error: %@", error);
            } else {
                productInfo = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
            // zrong 2015-03-22 END ========
            
            const char *charProductInfo;
            if(productInfo !=nil){
                charProductInfo =[productInfo UTF8String];
            }else{
                charProductInfo = "parse productInfo fail";
            }
            std::string stdstr(charProductInfo);
            callback((IAPProductRequest )ret,stdstr);
        }
    } else {
        PluginUtilsIOS::outputLog("Can't find the C++ object of the IAP plugin");
    }
}
@end
