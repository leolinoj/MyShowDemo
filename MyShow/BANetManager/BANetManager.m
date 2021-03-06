

#import "BANetManager.h"
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetExportSession.h>
#import <AVFoundation/AVMediaFormat.h>

/*! 系统相册 */
#import <AssetsLibrary/ALAsset.h>
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <AssetsLibrary/ALAssetsGroup.h>
#import <AssetsLibrary/ALAssetRepresentation.h>


#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"

//#import "UIImage+compressIMG.h"
#import "UIImage+CompressImage.h"


static NSMutableArray *tasks;


@implementation BANetManager

/*!
 *  获得全局唯一的网络请求实例单例方法
 *
 *  @return 网络请求类BANetManager单例
 */
+ (instancetype)sharedBANetManager
{
    static BANetManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        manager = [[self alloc] init];
        
    });
    return manager;
}

+ (AFHTTPSessionManager *)sharedAFManager
{
    static AFHTTPSessionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [AFHTTPSessionManager manager];
        
        /*! 设置请求超时时间 */
        manager.requestSerializer.timeoutInterval = 20;
        
        /*! 设置相应的缓存策略 */
        manager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

        /*! 设置返回数据为json, 分别设置请求以及相应的序列化器 */
        manager.responseSerializer = [AFJSONResponseSerializer serializer];

        AFJSONResponseSerializer * response = [AFJSONResponseSerializer serializer];
        response.removesKeysWithNullValues = YES;
        
        /*! 设置apikey ------类似于自己应用中的tokken---此处仅仅作为测试使用*/
//        [manager.requestSerializer setValue:apikey forHTTPHeaderField:@"apikey"];
        
        /*! 复杂的参数类型 需要使用json传值-设置请求内容的类型*/
//        [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        /*! 设置响应数据的基本了类型 */
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"text/css",@"text/xml",@"text/plain", @"application/javascript", nil];
        
        //        [manager.requestSerializer setValue:nil forHTTPHeaderField:nil];
       
        
//        NSString *sblx = @"0";
//        
//        NSString *ver = @"1.0";
//        
//        NSString *uid = [GLUserDataManager readMemberID];
//        
//        NSString *token = [GLUserDataManager readToken];
//        
//        //        NSString *HeaderStr = [NSString stringWithFormat:@"%@:%@:%@:%@",sblx,ver,uid,token];
//        
//        [manager.requestSerializer setValue:sblx forHTTPHeaderField:@"sblx"];
//        
//        [manager.requestSerializer setValue:ver forHTTPHeaderField:@"ver"];
//        
//        [manager.requestSerializer setValue:uid  forHTTPHeaderField:@"uid"];
//        
//        [manager.requestSerializer setValue:token forHTTPHeaderField:@"token"];
        

    });
    
    return manager;
}

+ (NSMutableArray *)tasks{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"创建数组");
        tasks = [[NSMutableArray alloc] init];
    });
    return tasks;
}

#pragma mark - ***** 网络请求的类方法---get/post
/*!
 *  网络请求的实例方法
 *
 *  @param type         get / post
 *  @param urlString    请求的地址
 *  @param paraments    请求的参数
 *  @param successBlock 请求成功的回调
 *  @param failureBlock 请求失败的回调
 *  @param progress 进度
 */
+ (BAURLSessionTask *)ba_requestWithType:(BAHttpRequestType)type withUrlString:(NSString *)urlString withParameters:(NSDictionary *)parameters withSuccessBlock:(BAResponseSuccess)successBlock withFailureBlock:(BAResponseFail)failureBlock progress:(BADownloadProgress)progress
{
    NSLog(@"请求地址----%@\n    请求参数----%@", urlString, parameters);
    if (urlString == nil)
    {
        return nil;
    }

    /*! 检查地址中是否有中文 */
    NSString *URLString = [NSURL URLWithString:urlString] ? urlString : [self strUTF8Encoding:urlString];
    
    BAURLSessionTask *sessionTask = nil;
    
    
    if (type == BAHttpRequestTypeGet)
    {
        sessionTask = [[self sharedAFManager] GET:URLString parameters:parameters  progress:^(NSProgress * _Nonnull downloadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            /****************************************************/
            // 如果请求成功 , 回调请求到的数据 , 同时 在这里 做本地缓存
            NSString *path = [NSString stringWithFormat:@"%ld.plist", [URLString hash]];
            // 存储的沙盒路径
            NSString *path_doc = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
            // 归档
            [NSKeyedArchiver archiveRootObject:responseObject toFile:[path_doc stringByAppendingPathComponent:path]];
            
            if (successBlock)
            {
                successBlock(responseObject);
            }
            
            [[self tasks] removeObject:sessionTask];
            
            //        [self writeInfoWithDict:(NSDictionary *)responseObject];
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            if (failureBlock)
            {
                failureBlock(error);
            }
            [[self tasks] removeObject:sessionTask];
            
        }];

    }
    else if (type == BAHttpRequestTypePost)
    {
        sessionTask = [[self sharedAFManager] POST:URLString parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            /* ************************************************** */
            // 如果请求成功 , 回调请求到的数据 , 同时 在这里 做本地缓存
            NSString *path = [NSString stringWithFormat:@"%ld.plist", [URLString hash]];
            // 存储的沙盒路径
            NSString *path_doc = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
            // 归档
            [NSKeyedArchiver archiveRootObject:responseObject toFile:[path_doc stringByAppendingPathComponent:path]];
            
            if (successBlock)
            {
                successBlock(responseObject);
            }
            
            [[self tasks] removeObject:sessionTask];
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            if (failureBlock)
            {
                failureBlock(error);
                NSLog(@"错误信息：%@",error);
            }
            [[self tasks] removeObject:sessionTask];

        }];
    }
    
    if (sessionTask)
    {
        [[self tasks] addObject:sessionTask];
    }
    
    return sessionTask;
}

/*!
 *  上传图片(多图)
 *
 *  @param operations   上传图片预留参数---视具体情况而定 可移除
 *  @param imageArray   上传的图片数组
 *  @parm width      图片要被压缩到的宽度
 *  @param urlString    上传的url
 *  @param successBlock 上传成功的回调
 *  @param failureBlock 上传失败的回调
 *  @param progress     上传进度
 */
+ (BAURLSessionTask *)ba_uploadImageWithUrlString:(NSString *)urlString parameters:(NSDictionary *)parameters withImageArray:(NSArray *)imageArray withSuccessBlock:(BAResponseSuccess)successBlock withFailurBlock:(BAResponseFail)failureBlock withUpLoadProgress:(BAUploadProgress)progress
{
    NSLog(@"请求地址----%@\n    请求参数----%@", urlString, imageArray);
    if (urlString == nil)
    {
        return nil;
    }
    
    /*! 检查地址中是否有中文 */
    NSString *URLString = [NSURL URLWithString:urlString] ? urlString : [self strUTF8Encoding:urlString];

    BAURLSessionTask *sessionTask = nil;
    sessionTask = [[self sharedAFManager] POST:URLString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        /*! 出于性能考虑,将上传图片进行压缩 */
        for (int i = 0; i < imageArray.count; i++)
        {
            /*! image的压缩方法 */
            UIImage *resizedImage;
            /*! 此处是使用原生系统相册 */
            if([imageArray[i] isKindOfClass:[ALAsset class]])
            {
                // 用ALAsset获取Asset URL  转化为image
                ALAssetRepresentation *assetRep = [imageArray[i] defaultRepresentation];
                
                CGImageRef imgRef = [assetRep fullResolutionImage];
                resizedImage = [UIImage imageWithCGImage:imgRef
                                          scale:1.0
                                    orientation:(UIImageOrientation)assetRep.orientation];
                //                imageWithImage
                NSLog(@"1111-----size : %@",NSStringFromCGSize(resizedImage.size));
                
                resizedImage = [self imageWithImage:resizedImage scaledToSize:resizedImage.size];
                NSLog(@"2222-----size : %@",NSStringFromCGSize(resizedImage.size));
            }
            else
            {
                /*! 此处是使用其他第三方相册，可以自由定制压缩方法 */
                resizedImage = imageArray[i];
            }
            
            /*! 此处压缩方法是jpeg格式是原图大小的0.8倍，要调整大小的话，就在这里调整就行了还是原图等比压缩 */
            NSData *imgData = UIImageJPEGRepresentation(resizedImage, 0.01);
            
            /*! 拼接data */
            if (imgData != nil)
            {   // 图片数据不为空才传递
//                [formData appendPartWithFileData:imgData name:imageArray[i] fileName:[NSString stringWithFormat:@"picflie%ld",(long)i] mimeType:@"image/jpeg"];    //这个估计也反了
                
        NSString * timestamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970] * 1000];
     [formData appendPartWithFileData:imgData name:@"file" fileName:[timestamp stringByAppendingString:@".jpg"]  mimeType:@"image/jpeg"];
            }
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        NSLog(@"上传进度--%lld,总进度---%lld",uploadProgress.completedUnitCount,uploadProgress.totalUnitCount);
        
        if (progress)
        {
            progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        }
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (successBlock)
        {
            successBlock(responseObject);
            
            NSLog(@"%@",[responseObject objectForKey:@"retmsg"]);
        }
        
        [[self tasks] removeObject:sessionTask];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (failureBlock)
        {
            failureBlock(error);
        }
        [[self tasks] removeObject:sessionTask];
    }];
    
    if (sessionTask)
    {
        [[self tasks] addObject:sessionTask];
    }
    
    return sessionTask;
}

/*!
 *  视频上传
 *
 *  @param operations   上传视频预留参数---视具体情况而定 可移除
 *  @param videoPath    上传视频的本地沙河路径
 *  @param urlString     上传的url
 *  @param successBlock 成功的回调
 *  @param failureBlock 失败的回调
 *  @param progress     上传的进度
 */
+ (void)ba_uploadVideoWithOperaitons:(NSDictionary *)operations withVideoPath:(NSString *)videoPath withUrlString:(NSString *)urlString withSuccessBlock:(BAResponseSuccess)successBlock withFailureBlock:(BAResponseFail)failureBlock withUploadProgress:(BAUploadProgress)progress
{
    /*! 获得视频资源 */
    AVURLAsset *avAsset = [AVURLAsset assetWithURL:[NSURL URLWithString:videoPath]];

    /*! 压缩 */
    
    //    NSString *const AVAssetExportPreset640x480;
    //    NSString *const AVAssetExportPreset960x540;
    //    NSString *const AVAssetExportPreset1280x720;
    //    NSString *const AVAssetExportPreset1920x1080;
    //    NSString *const AVAssetExportPreset3840x2160;
    
    AVAssetExportSession  *  avAssetExport = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPreset640x480];
    
    /*! 创建日期格式化器 */
    
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    
    /*! 转化后直接写入Library---caches */
    
    NSString *  videoWritePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingString:[NSString stringWithFormat:@"/output-%@.mp4",[formatter stringFromDate:[NSDate date]]]];
    
    
    avAssetExport.outputURL = [NSURL URLWithString:videoWritePath];
    
    
    avAssetExport.outputFileType =  AVFileTypeMPEG4;
    
    [avAssetExport exportAsynchronouslyWithCompletionHandler:^{
        
        switch ([avAssetExport status]) {
            case AVAssetExportSessionStatusCompleted:
            {
                [[self sharedAFManager] POST:urlString parameters:operations constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                    
                    //获得沙盒中的视频内容
                    
                    [formData appendPartWithFileURL:[NSURL fileURLWithPath:videoWritePath] name:@"write you want to writre" fileName:videoWritePath mimeType:@"video/mpeg4" error:nil];
                    
                } progress:^(NSProgress * _Nonnull uploadProgress) {
                    
                    NSLog(@"上传进度--%lld,总进度---%lld",uploadProgress.completedUnitCount,uploadProgress.totalUnitCount);
                    
                    if (progress)
                    {
                        progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
                    }
                    
                } success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *  _Nullable responseObject) {
                    
                    NSLog(@"上传视频成功 = %@",responseObject);
                    if (successBlock)
                    {
                        successBlock(responseObject);
                    }
                    
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    
                    if (failureBlock)
                    {
                        failureBlock(error);
                    }
                }];
                
                break;
            }
            default:
                break;
        }
        
        
    }];

}

#pragma mark - ***** 文件下载
/*!
 *  文件下载
 *
 *  @param operations   文件下载预留参数---视具体情况而定 可移除
 *  @param savePath     下载文件保存路径
 *  @param urlString        请求的url
 *  @param successBlock 下载文件成功的回调
 *  @param failureBlock 下载文件失败的回调
 *  @param progress     下载文件的进度显示
 */
+ (BAURLSessionTask *)ba_downLoadFileWithOperations:(NSDictionary *)operations withSavaPath:(NSString *)savePath withUrlString:(NSString *)urlString withSuccessBlock:(BAResponseSuccess)successBlock withFailureBlock:(BAResponseFail)failureBlock withDownLoadProgress:(BADownloadProgress)progress
{
    NSLog(@"请求地址----%@\n    请求参数----%@", urlString, operations);
    if (urlString == nil)
    {
        return nil;
    }

    NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];

    BAURLSessionTask *sessionTask = nil;
    
    sessionTask = [[self sharedAFManager] downloadTaskWithRequest:downloadRequest progress:^(NSProgress * _Nonnull downloadProgress) {
        
        NSLog(@"下载进度：%.2lld%%",100 * downloadProgress.completedUnitCount/downloadProgress.totalUnitCount);
        /*! 回到主线程刷新UI */
        dispatch_async(dispatch_get_main_queue(), ^{
           
            if (progress)
            {
                progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
            }
            
        });
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        if (!savePath)
        {
            NSURL *downloadURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
            NSLog(@"默认路径--%@",downloadURL);
            return [downloadURL URLByAppendingPathComponent:[response suggestedFilename]];
        }
        else
        {
            return [NSURL fileURLWithPath:savePath];
        }
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        [[self tasks] removeObject:sessionTask];

        NSLog(@"下载文件成功");
        if (error == nil)
        {
            if (successBlock)
            {
                /*! 返回完整路径 */
                successBlock([filePath path]);
            }
            else
            {
                if (failureBlock)
                {
                    failureBlock(error);
                }
            }
        }
    }];
    
    /*! 开始启动任务 */
    [sessionTask resume];
    
    if (sessionTask)
    {
        [[self tasks] addObject:sessionTask];
    }
    return sessionTask;
}

#pragma mark - ***** 开始监听网络连接
/*!
 *  开启网络监测
 */
+ (void)ba_startNetWorkMonitoring
{
    // 1.获得网络监控的管理者
//    AFNetworkReachabilityManager *mgr = [AFNetworkReachabilityManager sharedManager];
    // 当使用AF发送网络请求时,只要有网络操作,那么在状态栏(电池条)wifi符号旁边显示  菊花提示
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    // 2.设置网络状态改变后的处理
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        // 当网络状态改变了, 就会调用这个block
        switch (status)
        {
            case AFNetworkReachabilityStatusUnknown: // 未知网络
                NSLog(@"未知网络");
                BANetManagerShare.netWorkStatus = BANetworkStatusUnknown;
                break;
            case AFNetworkReachabilityStatusNotReachable: // 没有网络(断网)
                NSLog(@"没有网络");
                BANetManagerShare.netWorkStatus = BANetworkStatusNotReachable;
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN: // 手机自带网络
                NSLog(@"手机自带网络");
                BANetManagerShare.netWorkStatus = BANetworkStatusReachableViaWWAN;
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi: // WIFI
                
                BANetManagerShare.netWorkStatus = BANetworkStatusReachableViaWiFi;
                NSLog(@"WIFI--%lu", (unsigned long)BANetManagerShare.netWorkStatus);
                break;
        }
    }];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

/*! 对图片尺寸进行压缩 */
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    if (newSize.height > 375/newSize.width*newSize.height)
    {
        newSize.height = 375/newSize.width*newSize.height;
    }
    
    if (newSize.width > 375)
    {
        newSize.width = 375;
    }
    
    UIImage *newImage = [UIImage needCenterImage:image size:newSize scale:1.0];
    
    return newImage;
}

+ (NSString *)strUTF8Encoding:(NSString *)str
{
    /*! ios9适配的话 打开第一个 */
    //return [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    return [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end
