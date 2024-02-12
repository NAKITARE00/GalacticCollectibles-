/* eslint-disable @next/next/no-img-element */
/* eslint-disable react/no-unescaped-entities */
import React from "react";

export default function MoreInfo() {
  return (
    <div className="w-full relative ">
      <div className="w-full ">
        <img src="bg.png" alt="" className="w-full " />
      </div>
      
     <div className="w-full flex justify-center items-center">
      <div className="flex gradient sm:max-w-xl  max-w-md border-2 border-gray-400 absolute sm:-bottom-12 sm:right-10 rounded-xl backdrop-blur-md flex-col px-6 py-3 justify-center items-center text-center ">
        <h1 className="font-mono text-4xl sm:text-5xl py-4">What's GalacticCollectibles ?</h1>
        <p className="text-xl">
        This project aims to revolutionize the way amateur astronomers engage with the cosmos by creating a dedicated NFT marketplace and community. This platform will empower enthusiasts to explore, share, and monetize their astronomical discoveries through non-fungible tokens (NFTs). By combining blockchain technology, community collaboration, and educational resources, the project seeks to foster a thriving ecosystem for amateur astronomers.
        </p>
      </div>
    </div> 
    </div>
  );
}
