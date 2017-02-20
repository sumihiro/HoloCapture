//
//  LibraryViewController.m
//  HoloCapture
//
//  Created by 上田 澄博 on 2017/02/20.
//  Copyright © 2017年 Sumihiro Ueda. All rights reserved.
//

#import "LibraryViewController.h"
#import "ThumbnailCell.h"
#import "LibararyItemViewController.h"
#import <SVProgressHUD.h>

@interface LibraryViewController ()

@property (nonnull,strong) NSArray *recordings;

@end

@implementation LibraryViewController

static NSString * const reuseIdentifierForThumbNailCell = @"ThumbnailCell";
static NSString * const reuseIdentifierForBigThumbNailCell = @"BigThumbnailCell";
static NSString * const reuseIdentifierForAddCell = @"AddCell";


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
//    [self.collectionView registerClass:[ThumbnailCell class] forCellWithReuseIdentifier:reuseIdentifierForThumbNailCell];
//    [self.collectionView registerClass:[ThumbnailCell class] forCellWithReuseIdentifier:reuseIdentifierForBigThumbNailCell];
//    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifierForAddCell];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES];
    [self reload];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    UICollectionViewFlowLayout *flowLayout = (id)self.collectionView.collectionViewLayout;
    
    [flowLayout invalidateLayout];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        return self.recordings.count > 1 ? 1 : 0;
    } else {
        return 1 + self.recordings.count - 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell;
    
    if (indexPath.section == 0) {
        // big thumbnail
        HoloMrcRecording *record = [self.recordings objectAtIndex:indexPath.item];
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifierForBigThumbNailCell forIndexPath:indexPath];
        ThumbnailCell *tc = (ThumbnailCell*)cell;
        [tc.imageView sd_setImageWithURL:[self.client mrcThumbnailURL:record]
                        placeholderImage:nil
                                 options:SDWebImageAllowInvalidSSLCertificates
         ];
    } else {
        if (indexPath.item == 0) {
            // add cell
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifierForAddCell forIndexPath:indexPath];
        } else {
            HoloMrcRecording *record = [self.recordings objectAtIndex:indexPath.item];
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifierForThumbNailCell forIndexPath:indexPath];
            ThumbnailCell *tc = (ThumbnailCell*)cell;
            [tc.imageView sd_setImageWithURL:[self.client mrcThumbnailURL:record]
                            placeholderImage:nil
                                     options:SDWebImageAllowInvalidSSLCertificates
             ];
        }
    }
    
    // Configure the cell
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.view.bounds.size.height > self.view.bounds.size.width) {
        if (indexPath.section == 0) {
            CGFloat width = collectionView.bounds.size.width;
            return CGSizeMake(width,width);
        } else {
            CGFloat width = collectionView.bounds.size.width / 3;
            return CGSizeMake(width,width);
        }
    } else {
        if (indexPath.section == 0) {
            CGFloat height = collectionView.bounds.size.height / 4;
            return CGSizeMake(self.view.bounds.size.width,height);
        } else {
            CGFloat width = collectionView.bounds.size.width / 7;
            return CGSizeMake(width,width);
        }
    }
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.item == 0) {
        // capture
        [self capture];
    }
}

#pragma mark -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"select"]) {
        NSIndexPath *index = [self.collectionView indexPathForCell:sender];
        LibararyItemViewController *vc = segue.destinationViewController;
        vc.client = self.client;
        vc.reording = self.recordings[index.item];
    }
}

#pragma mark -

- (void)takePicure {
    [SVProgressHUD show];
    [self.client mrcTakePictureHolo:YES pv:YES success:^{
        [self reload];
        SVProgressHUDMaskType oldType = [SVProgressHUD new].defaultMaskType;
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
            
        [SVProgressHUD dismiss];
        [SVProgressHUD showSuccessWithStatus:nil];
        [SVProgressHUD dismissWithDelay:2.];
            
        [SVProgressHUD setDefaultMaskType:oldType];

    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }];
}

- (void)capture {
    UIAlertController *vc = [UIAlertController alertControllerWithTitle:@"Capture" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *photo = [UIAlertAction actionWithTitle:@"Take Picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self takePicure];
    }];
    [vc addAction:photo];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [vc addAction:cancel];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)reload {
    [self.client mrcFiles:^(NSArray<HoloMrcRecording *> *list) {
        self.recordings = list;
        [self.collectionView reloadData];
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }];
}

#pragma mark -

- (IBAction)pushReload:(id)sender {
    [self reload];
}

@end
