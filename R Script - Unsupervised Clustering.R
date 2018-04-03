# Load Libraries
library(png)
library(imager)
library(dplyr)
library(Rtsne)
library(dbscan)
library(fpc)
library(gridExtra)  
library(cluster) 
library(ggplot2)
library(kernlab)

# Clustering on Dynamic Spiral Drawings####
setwd("C:/Users/Spurthi Bollina/Documents/A&F/PARKINSON_HW/hw_drawings/Dynamic Spiral Test/")

# Reading Image names 
imageNames_D <- list.files(path="C:/Users/Spurthi Bollina/Documents/A&F/PARKINSON_HW/hw_drawings/Dynamic Spiral Test/",
                           pattern=".png",all.files=T, full.names=F, no.. = T)

# Data Exploration
im1 = load.image(imageNames_D[1])
dim(im1) # 561 X 420 X 1 X 3
im2 = load.image(imageNames_D[4])
plot(im1)
plot(im2)

# Observation: Although all the images are of same size,
#              there is some inconsistency with regards to the axis.
#              To avoid this, only including pixels in blue
#              (only spiral drawings which excludes axis in black)

## Reading Images 
read_image <- function(image_name){
  # reads in the .png image
  im = readPNG(image_name)
  # creates a dataframe with signle column keeping only blue pixels and rest masked as white.
  imageDF = data.frame(blue_pixels = ifelse(as.vector(im[,,1]) == 0 
                                            & as.vector(im[,,2]) == 0 
                                            & as.vector(im[,,3]) == 1, 1, 0))
  #changes the column name to the image file name
  colnames(imageDF)[1] = substr(image_name, 1, nchar(image_name)-4)
  return(imageDF)
}


## Creating Image Data Frame ####
# Creating a dummy table with rows equal to the size of image
# nrow = size of the image (561 * 420)
table_cat <- data.frame(dummy = matrix(NA, nrow = 235620))
# circles through all the images and concatenates the image dataframes created in the above step
for (i in imageNames_D){
  table_cat <- cbind(table_cat,df = read_image(i))
} 
# deletes the dummy column, and restore the pixel values for all the images.
table_cat$dummy <- NULL
imageDF = as.data.frame(t(table_cat))

#sum(imageDF$V1 ==1)/(nrow(imageDF)*ncol(imageDF))
  


# observation: In the finalized dataframe, there are 235620 pixel values 
#               and are filled with binary values. Applying dimensionality reduction techniques
#               to capture the variance in fewer dimensions.

## Dimensionality Reduction #### 
# t-SNE
tsne_DimensionalityReduction <- function(imageDF){ 
  set.seed(9)  
  tsne_model_1 = Rtsne(as.matrix(imageDF), check_duplicates=FALSE,
                       pca=TRUE, perplexity=5, theta=.5, dims=2)
  ## getting the two dimension matrix
  d_tsne_1 = as.data.frame(tsne_model_1$Y)  
  return(d_tsne_1)
}

tsneDF = tsne_DimensionalityReduction(imageDF) 
## plotting the t-sne results without clustering
ggplot(tsneDF, aes(x=V1, y=V2)) +  
  geom_point(size=2) +
  guides(colour=guide_legend(override.aes=list(size=15))) +
  #xlab("") + ylab("") +
  ggtitle("t-SNE with perplexity=5") +
  theme_light(base_size=20) +
  theme(axis.text.x=element_blank(),
        axis.text.y=element_blank()) +
  scale_colour_brewer(palette = "Set2")

# Identifying ideal number of clusters ####

# Elbow Method for finding the optimal number of clusters
set.seed(123)
# Compute and plot wss for k = 2 to k = 15.
k.max <- 8
data <- scale(tsneDF)
wss <- sapply(1:k.max, 
              function(k){kmeans(data, k, nstart=50,iter.max = 15 )$tot.withinss})
wss
plot(1:k.max, wss,
     type="b", pch = 19, frame = FALSE, 
     xlab="Number of clusters K",
     ylab="Total within-clusters sum of squares")


## Clustering Techniques ####

clustering <- function(tsneDF_copy, clusters, imageNames_D) {
    set.seed(123)
    #keeping a copy of the original
    tsneDF_orginal = tsneDF_copy
    
    # Creating k-means clustering model, and assigning the result to the data used to create the tsne
    fit_cluster_kmeans=kmeans(scale(tsneDF_copy), centers = clusters, nstart = 5, algorithm = c("Lloyd") ) 
    tsneDF_orginal$cl_kmeans = factor(fit_cluster_kmeans$cluster)
    fit_cluster_kmeans$size
    fit_cluster_kmeans
    # Centroid Plot against 1st 2 discriminant functions
    plot(tsneDF_copy$V1, tsneDF_copy$V2, type="n", xlab="Component 1", ylab="Component 2", main = "KMeans Clustering Solution")
    text(x=tsneDF_copy$V1, y=tsneDF_copy$V2, labels= imageNames_D,col=fit_cluster_kmeans$cluster+1)
    
    # Creating hierarchical cluster model, and assigning the result to the data used to create the tsne
    fit_cluster_hierarchical=hclust(dist(scale(tsneDF_copy), method = 'euclidean'), method = 'complete')
    tsneDF_orginal$cl_hierarchical = factor(cutree(fit_cluster_hierarchical, k=clusters)) 
    #Dendogram for hierarchical clustering
    plot(fit_cluster_hierarchical)
    rect.hclust(fit_cluster_hierarchical, k = clusters,border = 'red')
    
    # DBSCAN 
    fit_cluster_dbscan = dbscan(scale(tsneDF_copy), clusters)
    tsneDF_orginal$cl_dbscan = factor(fit_cluster_dbscan$cluster)
    # Plotting data points asper spectral cluster centers
    plot(tsneDF_copy$V1, tsneDF_copy$V2, type="n", xlab="Component 1", ylab="Component 2", main = "DBSCAN Clustering Solution")
    text(x=tsneDF_copy$V1, y=tsneDF_copy$V2, labels= imageNames_D,col=fit_cluster_dbscan$cluster)
    
    # Spectral
    fit_cluster_sc = specc(scale(tsneDF_copy), centers = clusters)
    tsneDF_orginal$cl_sc = factor(fit_cluster_sc)
    # Plotting data points asper spectral cluster centers
    plot(tsneDF_copy$V1, tsneDF_copy$V2, type="n", xlab="Component 1", ylab="Component 2", main = "Spectral Clustering Solution")
    text(x=tsneDF_copy$V1, y=tsneDF_copy$V2, labels= imageNames_D,col=fit_cluster_sc)

    return(tsneDF_orginal)
}


# Function to plot clusters
plot_cluster=function(data, var_cluster, palette)  
{
  ggplot(data, aes_string(x="V1", y="V2", color=var_cluster)) +
    geom_point(size=2) +
    guides(colour=guide_legend(override.aes=list(size=6))) +
    xlab("") + ylab("") +
    ggtitle("") +
    theme_light(base_size=20) +
    theme(axis.text.x=element_blank(),
          axis.text.y=element_blank(),
          legend.direction = "horizontal", 
          legend.position = "bottom",
          legend.box = "horizontal") + 
    scale_colour_brewer(palette = palette) 
}

clustered_tsneDF = clustering(tsneDF,2, imageNames_D) 
plot_k=plot_cluster(clustered_tsneDF, "cl_kmeans", "Set1")  
plot_h=plot_cluster(clustered_tsneDF, "cl_hierarchical", "Set2")
plot_d=plot_cluster(clustered_tsneDF, "cl_dbscan", "Set1")  
plot_s=plot_cluster(clustered_tsneDF, "cl_sc", "Set2")

## and finally: putting the plots side by side with gridExtra lib...
grid.arrange(plot_k, plot_h, ncol=2)  
grid.arrange(plot_d, plot_s, ncol=2)  

# Observations on Clusters: KMeans, Hierarchical and Spectral clusters have considerable number of points 
#                            in each cluster and are further investigated

## Evaluating Cluster Analysis ####
Cluster_solution = data.frame(Drawing = rownames(imageDF) ,UnsupervisedClusters_kmeans = as.numeric(clustered_tsneDF$cl_kmeans)-1, UnsupervisedClusters_hierarchical = as.numeric(clustered_tsneDF$cl_hierarchical)-1, UnsupervisedClusters_sc = as.numeric(clustered_tsneDF$cl_sc)-1)
Cluster_solution$manual_classification = c("np",	"p",	"np",	"p",	"np",
                                           "p",	"np",	"p",	"np",	"p",	"np",
                                           "np",	"p",	"np",	"np",	"p",	"p",
                                           "np",	"np",	"np",	"np",	"p",	"p",	"np",	"p")
# Confusion Matrix 
confusionMatrix <- function(df,col){
  cf = table(Cluster_solution$manual_classification, df[,col])
  accuracy = (cf[[1]] +cf[[4]]) /nrow(df)    
  return (list(cf, accuracy))
}

confusionMatrix(Cluster_solution,"UnsupervisedClusters_kmeans")
confusionMatrix(Cluster_solution,"UnsupervisedClusters_hierarchical")
confusionMatrix(Cluster_solution,"UnsupervisedClusters_sc")

ClusterDynamicSpiralTest = Cluster_solution[c("Drawing","UnsupervisedClusters_kmeans")]
write.csv(ClusterDynamicSpiralTest, file = "DynamicSpiralTest Clusters.csv", row.names = FALSE) 




####............... Testing with Static Spiral Drawings.............. ####


setwd("C:/Users/Spurthi Bollina/Documents/A&F/PARKINSON_HW/hw_drawings/Static Spiral Test/")

# Reading Image names 
imageNames_DS <- list.files(path="C:/Users/Spurthi Bollina/Documents/A&F/PARKINSON_HW/hw_drawings/Static Spiral Test/",
                           pattern=".png",all.files=T, full.names=F, no.. = T)

# Reads in Images and creates a dataframe
table_cat <- data.frame(dummy = matrix(NA, nrow = 235620))
for (i in imageNames_DS){
  table_cat <- cbind(table_cat,df = read_image(i))
}
# deletes the dummy column, and restore the pixel values for all the images.
table_cat$dummy <- NULL
imageDF = as.data.frame(t(table_cat))

# In the finalized dataframe, there are 235620 pixel values and are filled with binary values.
# Applying dimensionality reduction techniques to capture the variance in fewer dimensions.


# t-SNE for Dimensionality Reduction
tsneDF = tsne_DimensionalityReduction(imageDF) 


## Clustering Techniques
clustered_tsneDF = clustering(tsneDF,2, imageNames_DS) 
plot_k=plot_cluster(clustered_tsneDF, "cl_kmeans", "Set1")  
plot_h=plot_cluster(clustered_tsneDF, "cl_hierarchical", "Set2")
plot_d=plot_cluster(clustered_tsneDF, "cl_dbscan", "Set1")  
plot_s=plot_cluster(clustered_tsneDF, "cl_sc", "Set2")

## and finally: putting the plots side by side with gridExtra lib...
grid.arrange(plot_k, plot_h, ncol=2)  
grid.arrange(plot_d, plot_s, ncol=2)  

# Observations on Clusters: KMeans and Hierarchical have considerable number of points in each cluster and are further investigated

## Evaluating Cluster Analysis 
Cluster_solution = data.frame(Drawing = rownames(imageDF) ,UnsupervisedClusters_kmeans = as.numeric(clustered_tsneDF$cl_kmeans)-1, UnsupervisedClusters_hierarchical = as.numeric(clustered_tsneDF$cl_hierarchical)-1, UnsupervisedClusters_sc = as.numeric(clustered_tsneDF$cl_sc)-1)
Cluster_solution$manual_classification = substr(Cluster_solution$Drawing,0,1)

confusionMatrix(Cluster_solution,"UnsupervisedClusters_kmeans")
confusionMatrix(Cluster_solution,"UnsupervisedClusters_hierarchical")
confusionMatrix(Cluster_solution,"UnsupervisedClusters_sc")

ClusterStaticSpiralTest = Cluster_solution[c("Drawing","UnsupervisedClusters_kmeans")]
write.csv(ClusterStaticSpiralTest, file = "StaticSpiralTest Clusters.csv", row.names = FALSE)




